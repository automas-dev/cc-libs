local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('location')

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local vert_norm = Vec3:new(0, 1, 0)

---@enum Compass
local Compass = {
    NORTH = 1,
    EAST = 2,
    SOUTH = 3,
    WEST = 4,
}

---@enum Action
local Action = {
    FORWARD = 1,
    BACKWARD = 2,
    UP = 3,
    DOWN = 4,
    TURN_LEFT = 5,
    TURN_RIGHT = 6,
}

local static_name = {
    'North',
    'East',
    'South',
    'West',
}

local static_delta = {
    Vec3:new(0, 0, -1),
    Vec3:new(1, 0, 0),
    Vec3:new(0, 0, 1),
    Vec3:new(-1, 0, 0),
}

---@class Location
---@field pos Vec3 current location
---@field heading Compass current heading
---@field has_fix boolean location is known
---@field has_heading boolean heading is known
---@field debug_location boolean use gps to validate location after updates
---@field maps Map[] optional maps to update
local Location = {}

---Create a new Location object with locate function.
---@param map? Map
---@return Location
function Location:new(map)
    local x, y, z = gps.locate(0, false)

    if x ~= nil then
        log:debug('Got gps starting location', Vec3:new(x, y, z))
    else
        log:debug('No gps available for starting location')
    end

    local o = {
        pos = Vec3:new(x, y, z),
        heading = Compass.NORTH,
        has_fix = x ~= nil,
        has_heading = false,
        debug_location = false,
        maps = { map },
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Assign the map to be updated
---@param map Map
function Location:add_map(map)
    for _, m in ipairs(self.maps) do
        if m == map then
            -- Using tostring here to get map hash instead of pretty table
            log:warning('Tried to re-add map', tostring(map))
            return false
        end
    end

    -- Using tostring here to get map hash instead of pretty table
    log:debug('Adding map', tostring(map), 'to Location')
    table.insert(self.maps, map)
    return true
end

---Get the current location as position and heading
---@return Vec3 position
---@return Compass heading
function Location:location()
    return self.pos, self.heading
end

---Get a string name representing the current heading
---@return string heading name
function Location:heading_name()
    assert(self.heading >= 1 and self.heading <= 4, 'Heading is an unknown value ' .. self.heading)
    return static_name[self.heading]
end

---Get the delta vector for forwards
---@return Vec3 forwards vector
function Location:delta()
    assert(self.heading >= 1 and self.heading <= 4, 'Heading is an unknown value ' .. self.heading)
    return static_delta[self.heading]
end

---Get heading from motion delta
---@param delta Vec3 motion delta
function Location:set_heading_from_delta(delta)
    log:trace('Getting heading from delta', delta)
    if delta.x ~= 0 then
        log:trace('Delta x', delta.x)
        self.heading = delta.x > 0 and Compass.EAST or Compass.WEST
        self.has_heading = true
        log:debug('Got heading', self:heading_name(), 'from delta', delta)
    elseif delta.z ~= 0 then
        log:trace('Delta z', delta.z)
        self.heading = delta.z > 0 and Compass.SOUTH or Compass.NORTH
        self.has_heading = true
        log:debug('Got heading', self:heading_name(), 'from delta', delta)
    else
        log:error('Could not find delta direction')
    end
end

---Update position or rotation based on action
---Throws an error for invalid action or gps unavailable when debug_location is true
---@param action Action
function Location:update(action)
    -- Used to update map at end of function
    local pos_before_move = self.pos

    -- Try to get heading from first move if gps is available
    if not self.has_heading and self.has_fix and (action == Action.FORWARD or action == Action.BACKWARD) then
        local x, y, z = gps.locate(0, false)
        if x ~= nil then
            local pos = Vec3:new(x, y, z)
            log:debug('Using gps for heading from', pos_before_move, 'to', pos)
            local delta = pos - pos_before_move
            if action == Action.BACKWARD then
                delta = -delta
            end
            self:set_heading_from_delta(delta)
        else
            log:debug('No gps available for heading')
        end
    end

    -- Update position and heading from action
    if action == Action.FORWARD then
        local delta = self:delta()
        self.pos = self.pos + delta
    elseif action == Action.BACKWARD then
        local delta = self:delta()
        self.pos = self.pos - delta
    elseif action == Action.UP then
        self.pos = self.pos + vert_norm
    elseif action == Action.DOWN then
        self.pos = self.pos - vert_norm
    elseif action == Action.TURN_LEFT then
        self.heading = self.heading - 1
        if self.heading < 1 then
            self.heading = 4
        end
    elseif action == Action.TURN_RIGHT then
        self.heading = self.heading + 1
        if self.heading > 4 then
            self.heading = 1
        end
    else
        log:fatal('Unknown action', action)
    end

    -- Validate new position using gps
    if self.debug_location then
        local x, y, z = gps.locate(0, false)
        local pos = Vec3:new(x, y, z)
        if x == nil then
            log:error('Could not debug location, gps not available')
        elseif pos ~= self.pos then
            log:fatal('Location error, position', pos, 'does not match expected', self.pos)
        end
    end

    -- Add a connection to the map
    for _, map in ipairs(self.maps) do
        map:link(pos_before_move, self.pos)
    end
end

---@class LocalFrame
---@field origin Vec3
---@field heading Compass
---@field heading_diff number
local LocalFrame = {}

---Create a new LocalFrame
---@param origin Vec3 position in global frame of local frame origin
---@param heading? Compass heading of the frame, defaults to NORTH
---@return LocalFrame
function LocalFrame:new(origin, heading)
    heading = heading or Compass.NORTH
    local diff = heading - 1
    local o = {
        origin = origin,
        heading = heading,
        heading_diff = diff,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Rotate a vector around the y axis
---@param origin Vec3
---@param vec Vec3
---@param curr_heading Compass
---@param target_heading Compass
---@return Vec3
local function rotate_around_y(origin, vec, curr_heading, target_heading)
    if curr_heading == target_heading then
        return vec
    end
    vec = vec - origin
    local heading_diff = target_heading - curr_heading
    assert(math.abs(heading_diff) < 4)
    if heading_diff < 0 then
        heading_diff = heading_diff + 4
    end
    assert(math.abs(heading_diff) > 0)
    assert(math.abs(heading_diff) < 4)
    local turn_right = heading_diff == 1
    local turn_around = heading_diff == 2
    local turn_left = heading_diff == 3
    if turn_right then
        local old_x = vec.x
        vec.x = -vec.z
        vec.z = old_x
    elseif turn_around then
        vec.x = -vec.x
        vec.z = -vec.z
    elseif turn_left then
        local old_x = vec.x
        vec.x = vec.z
        vec.z = -old_x
    end
    return vec + origin
end

---Convert global position and heading to local
---@param pos Vec3 position in global frame
---@param heading? Compass heading in global frame, default assumes North
---@return Vec3 local position in local frame
---@return Compass heading heading in local frame
function LocalFrame:to_local(pos, heading)
    local local_pos = pos - self.origin
    heading = heading or Compass.NORTH
    local local_heading = heading + self.heading_diff
    local_pos = rotate_around_y(Vec3:new(0, 0, 0), local_pos, heading, local_heading)
    if local_heading < 1 then
        local_heading = local_heading + 4
    elseif local_heading > 4 then
        local_heading = local_heading - 4
    end
    return local_pos, local_heading
end

---Convert local position and heading to global
---@param pos Vec3 position in local frame
---@param heading? Compass heading in local frame
---@return Vec3 local position in global frame
---@return Compass? heading heading in global frame
function LocalFrame:to_global(pos, heading)
    local global_pos = pos + self.origin
    local heading_diff = self.heading - 1
    local global_heading = heading + heading_diff
    heading = heading or Compass.NORTH
    global_pos = rotate_around_y(self.origin, global_pos, heading, Compass.NORTH)
    if global_heading < 1 then
        global_heading = global_heading + 4
    elseif global_heading > 4 then
        global_heading = global_heading - 4
    end
    return global_pos, global_heading
end

local M = {
    Compass = Compass,
    CompassName = static_name,
    Action = Action,
    Location = Location,
    LocalFrame = LocalFrame,
    ---@type Location?
    _location = nil,
}

---Get global location object
---@return Location
function M.get_location()
    if M._location == nil then
        log:debug('Creating global Location object')
        M._location = Location:new()
    end
    return M._location
end

return M
