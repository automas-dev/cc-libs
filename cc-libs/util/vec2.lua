local Vec2 = {}

--- Create a new empty map
function Vec2:new(x, y)
    local o = {
        x = x,
        y = y,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

Vec2.__add = function(a, b)
    return Vec2:new(a, b)
end

local M = {
    Vec2 = Vec2
}

return Vec2
