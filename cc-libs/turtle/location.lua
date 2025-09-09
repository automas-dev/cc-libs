local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('location')

local vec = require 'cc-libs.util.vec'
local vec3 = vec.vec3

local vert_norm = vec3:new(0, 1, 0)

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
    vec3:new(0, 0, -1),
    vec3:new(1, 0, 0),
    vec3:new(0, 0, 1),
    vec3:new(-1, 0, 0),
}

---@class Location
---@field pos vec3
---@field heading Compass
---@field has_fix boolean
---@field has_heading boolean
---@field debug_location boolean
local Location = {}

---Create a new
---@return Location
function Location:new()
    local x, y, z = gps.locate()

    if x ~= nil then
        log:debug('Got gps starting location', vec3:new(x, y, z))
    end

    local o = {
        pos = vec3:new(x, y, z),
        heading = Compass.NORTH,
        has_fix = x ~= nil,
        has_heading = false,
        debug_location = false,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Get the current location as position and heading
---@return vec3 position
---@return Compass heading
function Location:location()
    return self.pos, self.heading
end

---Get a string name representing the current heading
---@return string heading name
function Location:direction_name()
    assert(self.heading >= 1 and self.heading <= 4, 'Direction is an unknown value ' .. self.heading)
    return static_name[self.heading]
end

---Get the delta vector for forwards
---@return vec3 forwards vector
function Location:delta()
    assert(self.heading >= 1 and self.heading <= 4, 'Direction is an unknown value ' .. self.heading)
    return static_delta[self.heading]
end

---Get heading from motion delta
---@param delta vec3 motion delta
function Location:set_heading_from_delta(delta)
    log:trace('Getting heading from delta', delta)
    if delta.x ~= 0 then
        log:trace('Delta x', delta.x)
        self.heading = delta.x > 0 and Compass.EAST or Compass.WEST
        self.has_heading = true
        log:debug('Got heading', self:direction_name(), 'from delta', delta)
    elseif delta.z ~= 0 then
        log:trace('Delta z', delta.z)
        self.heading = delta.z > 0 and Compass.SOUTH or Compass.NORTH
        self.has_heading = true
        log:debug('Got heading', self:direction_name(), 'from delta', delta)
    else
        log:error('Could not find delta direction')
    end
end

---Update position or rotation based on action
---@param action Action
function Location:update(action)
    -- Try to get heading from first move if gps is available
    if not self.has_heading and self.has_fix and (action == Action.FORWARD or action == Action.BACKWARD) then
        local x, y, z = gps.locate()
        if x ~= nil then
            local pos = vec3:new(x, y, z)
            local delta = pos - self.pos
            if action == Action.BACKWARD then
                delta = -delta
            end
            self:set_heading_from_delta(delta)
        end
    end

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
        log:error('Unknown action', action)
    end

    if self.debug_location then
        local x, y, z = gps.locate()
        local pos = vec3:new(x, y, z)
        if x == nil then
            log:error('Could not debug location, gps not available')
        elseif pos ~= self.pos then
            log:fatal('Location error, position', pos, 'does not match expected', self.pos)
        end
    end
end

local M = {
    Compass = Compass,
    CompassName = static_name,
    Action = Action,
    Location = Location,
}

return M
