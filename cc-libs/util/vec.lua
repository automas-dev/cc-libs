local vec2 = {}

function vec2:new(x, y)
    if y == nil then
        y = x
    end
    local o = {
        x = x or 0,
        y = y or 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

vec2.__add = function(a, b)
    return vec2:new(a.x + b.x, a.y + b.y)
end

vec2.__sub = function(a, b)
    return vec2:new(a.x - b.x, a.y - b.y)
end

vec2.__mul = function(a, b)
    return vec2:new(a.x * b.x, a.y * b.y)
end

vec2.__div = function(a, b)
    return vec2:new(a.x / b.x, a.y / b.y)
end

vec2.__mod = function(a, b)
    return vec2:new(a.x % b.x, a.y % b.y)
end

vec2.__pow = function(a, b)
    return vec2:new(a.x ^ b.x, a.y ^ b.y)
end

vec2.__len = function()
    return 2
end

vec2.__eq = function(a, b)
    return a.x == b.x and a.y == b.y
end

vec2.__index = function(a, key)
    print(a, key)
    if key == 0 then
        return a.x
    elseif key == 1 then
        return a.y
    elseif key == 'foo' then
        print('FOO')
        return 'bar'
    else
        return nil
    end
end

vec2.__newindex = function(a, key, value)
    if key == 0 then
        a.x = value
    elseif key == 1 then
        a.y = value
    end
end

vec2.__tostring = function(a)
    return 'vec2(' .. a.x .. ', ' .. a.y .. ')'
end

function vec2:get_length()
    if self.x == 0 and self.y == 0 then
        return 0
    else
        return math.sqrt(self.x ^ 2 + self.y ^ 2)
    end
end

function vec2:set_length(new_length)
    local length = self:get_length()
    self.x = self.x * new_length / length
    self.y = self.y * new_length / length
end

function vec2:rotate(angle_deg)
    local rad = math.rad(angle_deg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local new_x = self.x * cos - self.y * sin
    local new_y = self.x * sin + self.y * cos
    self.x = new_x
    self.y = new_y
end

function vec2:rotated(angle_deg)
    local new_vec = vec2:new(self.x, self.y)
    new_vec.rotate(angle_deg)
    return new_vec
end

function vec2:get_angle()
    if self:get_length() == 0 then
        return 0
    else
        return math.deg(math.atan(self.y, self.x))
    end
end

function vec2:set_angle(angle_deg)
    self.x = self:get_length()
    self.y = 0
    self.rotate(angle_deg)
end

function vec2:get_angle_between(other)
    local cross = self.x * other.y - self.y * other.x
    local dot = self.x * other.x + self.y * other.y
    return math.deg(math.atan(cross, dot))
end

function vec2:normalized()
    local length = self:get_length()
    -- if length != 0 then
    --     return 
    -- end
end

return {
    Vec2 = vec2,
}
