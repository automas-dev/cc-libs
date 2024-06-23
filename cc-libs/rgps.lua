---@module 'ccl_logging'
local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('rgps')

---@module 'ccl_vec'
local vec = require 'ccl-libs.util.vec'
local vec3 = vec.vec3

---@module 'ccl_map'

local vert_norm = vec3:new(0, 1, 0)

---@enum compass
local Compass = {
    N = 1,
    E = 2,
    S = 3,
    W = 4,
}

local static_name = {
    "North",
    "East",
    "South",
    "West",
}

local static_delta = {
    vec3:new(0, 0, 1),
    vec3:new(1, 0, 0),
    vec3:new(0, 0, -1),
    vec3:new(-1, 0, 0),
}

---@class RGPS
---@field pos vec3
---@field dir compass
---@field map cc_map
---@field max_tries number
local M = {
    Compass = Compass
}

---Create a new
---@param map cc_map
---@return table
function M:new(map)
    log:trace('New rgps instance')
    local o = {
        pos = vec3:new(0, 0, 0),
        dir = Compass.N,
        map = map,
        max_tries = 10,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:location()
    return self.pos, self.dir
end

function M:direction_name()
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)
    return static_name[self.dir]
end

function M:delta()
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)
    return static_delta[self.dir]
end

---Attempt an action up to self.max_tries times
---@param action function normally turtle.forward or .back or .up or .down
---@return boolean was the move a success
function M:_attempt_move(action)
    local success = false
    local tries = 0
    for i = 1, self.max_tries do
        tries = i
        if action() then
            success = true
            break
        end
    end
    log:trace('Attempt to move took', tries, 'tries and was', (success and 'success' or 'fail'))
    return success
end

function M:forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:trace('move forward', n, 'blocks')
    for _ = 1, n do
        local p1 = self.pos
        if not self:_attempt_move(turtle.forward) then
            error('Failed to move forward after ' .. self.max_tires .. 'attempts')
        end
        self.pos = self.pos + self:delta()
        if self.map then
            self.map:add(p1, self.pos)
        end
    end
    return true
end

function M:backward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:trace('move backward', n, 'blocks')
    for _ = 1, n do
        local p1 = self.pos
        if not self:_attempt_move(turtle.back) then
            error('Failed to move back after ' .. self.max_tires .. 'attempts')
        end
        self.pos = self.pos - self:delta()
        if self.map then
            self.map:add(p1, self.pos)
        end
    end
    return true
end

function M:up(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:trace('move up', n, 'blocks')
    for _ = 1, n do
        local p1 = self.pos
        if not self:_attempt_move(turtle.up) then
            error('Failed to move up after ' .. self.max_tires .. 'attempts')
        end
        self.pos = self.pos + vert_norm
        if self.map then
            self.map:add(p1, self.pos)
        end
    end
    return true
end

function M:down(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:trace('move down', n, 'blocks')
    for _ = 1, n do
        local p1 = self.pos
        if not turtle.down() then
            return false
        end
        self.pos = self.pos - vert_norm
        if self.map then
            self.map:add(p1, self.pos)
        end
    end
    return true
end

function M:left(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)

    if n == 0 then return end

    turtle.turnLeft()
    self.dir = self.dir - 1
    if self.dir < 1 then self.dir = 4 end

    self:left(n - 1)
end

function M:right(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)

    if n == 0 then return end

    turtle.turnRight()
    self.dir = self.dir + 1
    if self.dir > 4 then self.dir = 1 end

    self:right(n - 1)
end

function M:around()
    self:right(2)
end

function M:face(compass)
    assert(compass >= 1 and compass <= 4, 'Direction is an unknown value ' .. self.dir)
    log:trace('face', static_name[compass])

    if compass == self.dir + 2 or compass == self.dir - 2 then
        self:around()
    elseif compass == self.dir + 1 or compass == self.dir - 3 then
        self:right()
    elseif compass == self.dir - 1 or compass == self.dir + 3 then
        self:left()
    end
end

return M
