local rgps = require 'cc-libs.rgps'
local world = require 'cc-libs.map'
local astar = require 'cc-libs.astar'
local logging = require 'cc-libs.logging'
local log = logging.get_logger('nav')

local M = {}

function M:new(gps, map)
    map = map or world:new()
    local o = {
        gps = gps,
        station = gps.pos,
        resume = nil,
        map = map,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:reset()
    log:info('Reset')

    self.station = self.gps.pos
    self.resume = nil
end

function M:mark_resume()
    self.resume = self.gps.pos
    log:info('Mark resume point', self.resume)
end

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

function M:trace_step(step)
    log:debug('trace step to pos', step.x, step.y, step.z)
    local pos = self.gps.pos
    assert(is_inline(pos, step), 'Step is not inline with current position')
    log:trace('trace starts at pos', pos.x, pos.y, pos.z)

    if pos.x ~= step.x then
        local delta = math.abs(step.x - pos.x)

        if pos.x < step.x then
            self.gps:face(rgps.Compass.E)
        else
            self.gps:face(rgps.Compass.W)
        end

        self.gps:forward(delta)
    elseif pos.y ~= step.y then
        local delta = math.abs(step.y - pos.y)

        if pos.y < step.y then
            self.gps:up(delta)
        else
            self.gps:down(delta)
        end
    elseif pos.z ~= step.z then
        local delta = math.abs(step.z - pos.z)

        if pos.z < step.z then
            self.gps:face(rgps.Compass.N)
        else
            self.gps:face(rgps.Compass.S)
        end
        self.gps:forward(delta)
    end

    local end_pos = self.gps.pos
    local at_end_pos = end_pos.x == step.x
        and end_pos.y == step.y
        and end_pos.z == step.z

    assert(at_end_pos, 'trace_step did not reach step position')
end

function M:follow()
    log:info('Going to resume point')
    assert(self.resume ~= nil, 'No resume point is marked')
    assert(self.gps.pos == self.station, 'Not aligned with trace start')

    local path = self:find_path(self.station, self.resume)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function M:back_follow()
    log:info('Going to station point')
    assert(self.resume ~= nil, 'No resume point is marked')
    assert(self.gps.pos == self.resume, 'Not aligned with trace end')

    local path = self:find_path(self.resume, self.station)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function M:find_path(start, goal)
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

return M
