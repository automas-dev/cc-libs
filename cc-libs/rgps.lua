local logging = require 'cc-libs.logging'
local log = logging.get_logger('rgps')

local vert_norm = vector.new(0, 1, 0)

local Compass = {
    N = 1,
    E = 2,
    S = 3,
    W = 4,
}

local M = {
    Compass = Compass
}

local static_name = {
    "North",
    "East",
    "South",
    "West",
}

local static_delta = {
    vector.new(0, 0, 1),
    vector.new(1, 0, 0),
    vector.new(0, 0, -1),
    vector.new(-1, 0, 0),
}

function M:new(map)
    log:trace('New rgps instance')
    local o = {
        pos = vector.new(0, 0, 0),
        dir = Compass.N,
        map = map,
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

function M:forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:trace('move forward', n, 'blocks')
    for _ = 1, n do
        local p1 = self.pos
        if not turtle.forward() then
            return false
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
        if not turtle.back() then
            return false
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
        if not turtle.up() then
            return false
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
