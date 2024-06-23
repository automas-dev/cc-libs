---@meta ccl_rgps

---@module 'ccl_logging'
local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('rgps')

---@module 'ccl_vec'
local vec = require 'ccl-libs.util.vec'
local vec3 = vec.vec3

local vert_norm = vec3:new(0, 1, 0)

---@enum Compass
local Compass = {
    N = 1,
    E = 2,
    S = 3,
    W = 4,
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
---@field dir Compass
---@field max_tries number
local RGPS = {}

---Create a new
---@return RGPS
function RGPS:new()
    log:trace('New rgps instance')
    local o = {
        pos = vec3:new(0, 0, 0),
        dir = Compass.N,
        max_tries = 10,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function RGPS:location()
    return self.pos, self.dir
end

function RGPS:direction_name()
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)
    return static_name[self.dir]
end

function RGPS:delta()
    assert(self.dir >= 1 and self.dir <= 4, 'Direction is an unknown value ' .. self.dir)
    return static_delta[self.dir]
end

---Update position or rotation based on action
---@param action Action
function RGPS:update(action)
    if action == Action.FORWARD then
        self.pos = self.pos + self:delta()
    elseif action == Action.BACKWARD then
        self.pos = self.pos - self:delta()
    elseif action == Action.UP then
        self.pos = self.pos + vert_norm
    elseif action == Action.DOWN then
        self.pos = self.pos - vert_norm
    elseif action == Action.TURN_LEFT then
        self.dir = self.dir - 1
        if self.dir < 1 then
            self.dir = 4
        end
    elseif action == Action.TURN_RIGHT then
        self.dir = self.dir + 1
        if self.dir > 4 then
            self.dir = 1
        end
    end
end

local M = {
    Compass = Compass,
    Action = Action,
    RGPS = RGPS,
}

return M
