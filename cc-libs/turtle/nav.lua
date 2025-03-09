---@meta ccl_nav

---@module 'ccl_logging'
local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('nav')

---@module 'ccl_motion'

---@module 'ccl_vec'

---@module 'ccl_map'
local world = require 'cc-libs.map'

---@module 'ccl_rgps'
local rgps = require 'cc-libs.turtle.rgps'
local Compass = rgps.Compass
local CompassName = rgps.CompassName

local astar = require 'cc-libs.astar'

---@class Nav
---@field map Map
---@field motion Motion
---@field gps any
---@field station vec3
---@field resume? vec3
local Nav = {}

---Create a new navigation controller
---@param motion Motion controller to move the turtle
---@param gps any provides turtle position
---@param map? Map  map to store paths, will create new if nil
---@param station? vec3 location of the station, if nil will be set to gps.pos
---@return Nav
function Nav:new(motion, gps, map, station)
    map = map or world:new()
    station = station or gps.pos
    local o = {
        map = map,
        motion = motion,
        gps = gps,
        station = station,
        resume = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Clear the resume point and set the station to gps.pos
function Nav:reset()
    log:info('Reset')

    self.station = self.gps.pos
    self.resume = nil
end

---Mark the current location as a resume point
function Nav:mark_resume()
    self.resume = self.gps.pos
    log:info('Mark resume point', self.resume)
end

---Check if two points share the same value for at least 2 axis
---@param pos1 vec3
---@param pos2 vec3
---@return boolean
local function is_inline(pos1, pos2)
    if pos1.x ~= pos2.x then
        return pos1.y == pos2.y and pos1.z == pos2.z
    elseif pos1.y ~= pos2.y then
        return pos1.x == pos2.x and pos1.z == pos2.z
    elseif pos1.z ~= pos2.z then
        return pos1.x == pos2.x and pos1.y == pos2.y
    else
        return true
    end
end

function Nav:face(compass)
    assert(compass >= 1 and compass <= 4, 'Direction is an unknown value ' .. self.gps.dir)
    log:trace('face', CompassName[compass])

    if compass == self.gps.dir + 2 or compass == self.gps.dir - 2 then
        self.motion:around()
    elseif compass == self.gps.dir + 1 or compass == self.gps.dir - 3 then
        self.motion:right()
    elseif compass == self.gps.dir - 1 or compass == self.gps.dir + 3 then
        self.motion:left()
    end
end

---Move to the trace step
---@param step vec3 position to move to
function Nav:trace_step(step)
    log:debug('trace step to pos', step.x, step.y, step.z)
    local pos = self.gps.pos
    assert(is_inline(pos, step), 'Step is not inline with current position')
    log:trace('trace starts at pos', pos.x, pos.y, pos.z)

    if pos.x ~= step.x then
        local delta = math.abs(step.x - pos.x)

        if pos.x < step.x then
            self:face(Compass.E)
        else
            self:face(Compass.W)
        end

        self.motion:forward(delta)
    elseif pos.y ~= step.y then
        local delta = math.abs(step.y - pos.y)

        if pos.y < step.y then
            self.motion:up(delta)
        else
            self.motion:down(delta)
        end
    elseif pos.z ~= step.z then
        local delta = math.abs(step.z - pos.z)

        if pos.z < step.z then
            self:face(Compass.N)
        else
            self:face(Compass.S)
        end
        self.motion:forward(delta)
    end

    local end_pos = self.gps.pos
    local at_end_pos = end_pos.x == step.x
        and end_pos.y == step.y
        and end_pos.z == step.z

    assert(at_end_pos, 'trace_step did not reach step position')
end

function Nav:follow()
    log:info('Going to resume point')
    assert(self.resume ~= nil, 'No resume point is marked')
    assert(self.gps.pos == self.station, 'Not aligned with trace start')

    local path = self:find_path(self.station, self.resume)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function Nav:back_follow()
    log:info('Going to station point')
    assert(self.resume ~= nil, 'No resume point is marked')
    assert(self.gps.pos == self.resume, 'Not aligned with trace end')

    local path = self:find_path(self.resume, self.station)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function Nav:find_path(start, goal)
    log:debug('Searching for path between', start.x, start.y, start.z,
        'and', goal.x, goal.y, goal.z)

    log:debug('Start pos is', start.x, start.y, start.z)
    local p_start = self.map:point(start.x, start.y, start.z)

    log:debug('Goal pos is', goal.x, goal.y, goal.z)
    local p_goal = self.map:point(goal.x, goal.y, goal.z)

    local function neighbors(pid)
        log:trace('neighbors', pid)
        local point = self.map:get(pid)
        return point.links
    end

    local function f(n1, n2)
        log:trace('f', n1, n2)
        local dx = math.abs(self.map:get(n1).x - self.map:get(n2).x)
        local dy = math.abs(self.map:get(n1).y - self.map:get(n2).y)
        return dx + dy
    end

    local function h(n1, n2)
        log:trace('h', n1, n2)
        local dx = math.abs(self.map:get(n1).x - self.map:get(n2).x)
        local dy = math.abs(self.map:get(n1).y - self.map:get(n2).y)
        return math.sqrt(dx * dx + dy * dy)
    end

    local path = astar(p_start.id, p_goal.id, neighbors, f, h, true)
    log:debug('Path completed with', #path, 'points')

    local path_points = {}
    for i = 1, #path do
        path_points[i] = self.map:get(path[i])
    end

    return path_points
end

local M = {
    Nav = Nav,
}

return M
