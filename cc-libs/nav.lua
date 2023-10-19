local stack = require 'cc-libs.stack'
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
        trace = stack:new(),
        map = map,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:reset(mark)
    mark = mark or 0
    log:info('Reset to mark', mark)

    assert(mark >= 0, 'mark must be positive')
    assert(mark <= #self.trace, 'mark is in the future')

    while #self.trace > mark do
        self.trace:pop()
    end
end

function M:mark()
    log:info('mark index')
    self:push()
    return #self.trace
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

function M:push()
    log:debug('push index', #self.trace + 1)
    if #self.trace > 0 then
        local last_trace = self.trace:peek()
        log:trace('Trace has more than 1 point')
        log:trace('Checking that pos',
            self.gps.pos.x, self.gps.pos.y, self.gps.pos.z,
            'is inline with last trace',
            last_trace.x, last_trace.y, last_trace.z)
        assert(is_inline(self.gps.pos, last_trace), 'Current position is not inline with last push')
    end
    self.trace:push(self.gps.pos)
end

function M:pop()
    log:debug('pop index', #self.trace)
    return self.trace:pop()
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
    assert(self.gps.pos == self.trace[1], 'Not aligned with trace start')

    local path = self:find_path(1, #self.trace)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function M:back_follow()
    log:info('Going to station point')
    assert(self.gps.pos == self.trace[#self.trace], 'Not aligned with trace end')

    local path = self:find_path(#self.trace, 1)

    log:debug('Path has', #path, 'points')

    for i = 1, #path do
        self:trace_step(path[i])
    end
end

function M:find_path(start, goal)
    log:debug('Searching for path between', start, 'and', goal)
    assert(self.trace[start] ~= nil)
    assert(self.trace[goal] ~= nil)

    local start_pos = self.trace[start]
    log:debug('Start pos is', start_pos.x, start_pos.y, start_pos.z)
    local p_start = self.map:point(start_pos.x, start_pos.y, start_pos.z)

    local goal_pos = self.trace[goal]
    log:debug('Goal pos is', start_pos.x, start_pos.y, start_pos.z)
    local p_goal = self.map:point(goal_pos.x, goal_pos.y, goal_pos.z)

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
