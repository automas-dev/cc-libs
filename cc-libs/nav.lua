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
    assert(mark >= 0, 'mark must be positive')
    assert(mark <= #self.trace, 'mark is in the future')
    log:trace('reset to', mark)
    while #self.trace > mark do
        self.trace:pop()
    end
end

function M:mark()
    self:push()
    log:trace('mark index', #self.trace)
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
    if #self.trace > 0 then
        assert(is_inline(self.gps.pos, self.trace:peek()), 'Current position is not inline with last push')
    end
    self.trace:push(self.gps.pos)
    log:trace('push index', #self.trace)
end

function M:pop()
    log:trace('pop index', #self.trace)
    return self.trace:pop()
end

function M:trace_step(step)
    local pos = self.gps.pos
    assert(is_inline(pos, step), 'Step is not inline with current position')

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

    assert(self.gps.pos == step, 'trace_step did not reach step position')
end

function M:follow()
    assert(self.gps.pos == self.trace[1], 'Not aligned with trace start')

    for i = 1, #self.trace do
        self:trace_step(self.trace[i])
    end
end

function M:back_follow()
    assert(self.gps.pos == self.trace[#self.trace], 'Not aligned with trace end')

    for i = #self.trace, 1, -1 do
        self:trace_step(self.trace[i])
    end
end

function M:find_path(start, goal)
    assert(self.map.graph[start] ~= nil)
    assert(self.map.graph[goal] ~= nil)

    local p_start = self.map:get_point(start)
    local p_goal = self.map:get_point(goal)

    local function neighbors(point)
        return point.links
    end

    local function f(n1, n2)
        local dx = math.abs(self.map:get_point(n1).x - self.map:get_point(n2).x)
        local dy = math.abs(self.map:get_point(n1).y - self.map:get_point(n2).y)
        return dx + dy
    end

    local function h(n1, n2)
        local dx = math.abs(self.map:get_point(n1).x - self.map:get_point(n2).x)
        local dy = math.abs(self.map:get_point(n1).y - self.map:get_point(n2).y)
        return math.sqrt(dx * dx + dy * dy)
    end

    local path = astar(p_start.id, p_goal.id, neighbors, f, h)

    return path
end

return M
