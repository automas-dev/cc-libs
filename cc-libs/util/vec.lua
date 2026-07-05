---@class Vec2
---@field x number
---@field y number
---@operator add(Vec2): Vec2
---@operator add(number): Vec2
---@operator sub(Vec2): Vec2
---@operator sub(number): Vec2
---@operator mul(Vec2): Vec2
---@operator mul(number): Vec2
---@operator div(Vec2): Vec2
---@operator div(number): Vec2
---@operator mod(Vec2): Vec2
---@operator mod(number): Vec2
---@operator pow(Vec2): Vec2
---@operator pow(number): Vec2
---@operator unm(): Vec2
---@operator len(): integer
local Vec2 = {
    mt = {},
}
setmetatable(Vec2, Vec2.mt)

Vec2.mt.__call = function(_, x, y)
    return Vec2:new(x, y)
end

---Create a new Vec2
---@param x? number
---@param y? number
---@return Vec2
function Vec2:new(x, y)
    if y == nil then
        y = x
    end
    local o = {
        x = x or 0,
        y = y or 0,
    }
    setmetatable(o, self)
    return o
end

function Vec2.__index(a, key)
    if key == 1 then
        return a.x
    elseif key == 2 then
        return a.y
    else
        return Vec2[key]
    end
end

---Addition operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__add(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x + b, a.y + b)
    else
        return Vec2:new(a.x + b.x, a.y + b.y)
    end
end

---Subtraction operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__sub(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x - b, a.y - b)
    else
        return Vec2:new(a.x - b.x, a.y - b.y)
    end
end

---Multiply operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__mul(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x * b, a.y * b)
    else
        return Vec2:new(a.x * b.x, a.y * b.y)
    end
end

---Division operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__div(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x / b, a.y / b)
    else
        return Vec2:new(a.x / b.x, a.y / b.y)
    end
end

-- ---Floor division operator
-- ---@param a Vec2
-- ---@param b number|Vec2
-- ---@return Vec2
-- function Vec2.__idiv(a, b)
--     if type(b) == 'number' then
--         return Vec2:new(a.x // b, a.y // b)
--     else
--         return Vec2:new(a.x // b.x, a.y // b.y)
--     end
-- end

---Modulo operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__mod(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x % b, a.y % b)
    else
        return Vec2:new(a.x % b.x, a.y % b.y)
    end
end

---Negation operator
---@param a Vec2
---@return Vec2
function Vec2.__unm(a)
    return Vec2:new(-a.x, -a.y)
end

---Power operator
---@param a Vec2
---@param b number|Vec2
---@return Vec2
function Vec2.__pow(a, b)
    if type(b) == 'number' then
        return Vec2:new(a.x ^ b, a.y ^ b)
    else
        return Vec2:new(a.x ^ b.x, a.y ^ b.y)
    end
end

---Length of Vec2. Will always be 2.
---@return integer
function Vec2.__len()
    return 2
end

---Equality operator overload
---@param a Vec2
---@param b Vec2
---@return boolean
function Vec2.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

---Assign index operator
---@param a Vec2
---@param key integer must be 1 or 2
---@param value number
function Vec2.__newindex(a, key, value)
    if key == 1 then
        a.x = value
    elseif key == 2 then
        a.y = value
    end
end

---String conversion overload
---@param a Vec2
---@return string
function Vec2.__tostring(a)
    return 'Vec2(' .. a.x .. ', ' .. a.y .. ')'
end

---Get the length squared of this Vec2. This function is faster than the
---Vec2.get_length function and is useful for comparing two relative vectors.
---@return number
function Vec2:get_length2()
    if self.x == 0 and self.y == 0 then
        return 0
    else
        return self.x ^ 2 + self.y ^ 2
    end
end

---Get the length of this Vec2
---@return number
function Vec2:get_length()
    if self.x == 0 and self.y == 0 then
        return 0
    else
        return math.sqrt(self:get_length2())
    end
end

---Adjust x and y of this Vec2 to the new length
---@param new_length number
function Vec2:set_length(new_length)
    local length = self:get_length()
    if length == 0 then
        return
    end
    self.x = self.x * new_length / length
    self.y = self.y * new_length / length
end

---Rotate this Vec2 in place
---@param angle_deg number angle in degrees
function Vec2:rotate(angle_deg)
    local rad = math.rad(angle_deg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local new_x = self.x * cos - self.y * sin
    local new_y = self.x * sin + self.y * cos
    self.x = new_x
    self.y = new_y
end

---Return a new Vec2 that is rotated by angle_deg. This does not modify self.
---@param angle_deg number angle in degrees
---@return Vec2
function Vec2:rotated(angle_deg)
    local new_vec = Vec2:new(self.x, self.y)
    new_vec:rotate(angle_deg)
    return new_vec
end

---Get the angle in degrees of this Vec2
---@return number angle in degrees
function Vec2:get_angle()
    if self:get_length() == 0 then
        return 0
    else
        return math.deg(math.atan2(self.y, self.x))
    end
end

---Adjust x and y of this Vec2 to the new angle
---@param angle_deg number angle in degrees
function Vec2:set_angle(angle_deg)
    self.x = self:get_length()
    self.y = 0
    self:rotate(angle_deg)
end

---Get the angle between two Vec2s
---@param other Vec2
---@return number angle in degrees
function Vec2:get_angle_between(other)
    local cross = self.x * other.y - self.y * other.x
    local dot = self.x * other.x + self.y * other.y
    return math.deg(math.atan2(cross, dot))
end

---Get a new vector with length == 1 and a matching angle to this Vec2
---@return Vec2
function Vec2:normalized()
    local new_vec = Vec2:new(self.x, self.y)
    new_vec:set_length(1)
    return new_vec
end

---@class Vec3
---@field x number
---@field y number
---@field z number
---@operator add(Vec3): Vec3
---@operator add(number): Vec3
---@operator sub(Vec3): Vec3
---@operator sub(number): Vec3
---@operator mul(Vec3): Vec3
---@operator mul(number): Vec3
---@operator div(Vec3): Vec3
---@operator div(number): Vec3
---@operator mod(Vec3): Vec3
---@operator mod(number): Vec3
---@operator pow(Vec3): Vec3
---@operator pow(number): Vec3
---@operator unm(): Vec3
---@operator len(): integer
local Vec3 = {
    mt = {},
}
setmetatable(Vec3, Vec3.mt)

Vec3.mt.__call = function(_, x, y, z)
    return Vec3:new(x, y, z)
end

---Create a new Vec3
---@param x? number
---@param y? number
---@param z? number
---@return Vec3
function Vec3:new(x, y, z)
    assert(z ~= nil or y == nil, 'Only 2 values provided, need 1 or 3')
    if y == nil then
        y = x
        z = x
    end
    local o = {
        x = x or 0,
        y = y or 0,
        z = z or 0,
    }
    setmetatable(o, self)
    return o
end

Vec3.__index = function(a, key)
    if key == 1 then
        return a.x
    elseif key == 2 then
        return a.y
    elseif key == 3 then
        return a.z
    else
        return Vec3[key]
    end
end

---Addition operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__add = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x + b, a.y + b, a.z + b)
    else
        return Vec3:new(a.x + b.x, a.y + b.y, a.z + b.z)
    end
end

---Subtraction operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__sub = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x - b, a.y - b, a.z - b)
    else
        return Vec3:new(a.x - b.x, a.y - b.y, a.z - b.z)
    end
end

---Multiply operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__mul = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x * b, a.y * b, a.z * b)
    else
        return Vec3:new(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

---Division operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__div = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x / b, a.y / b, a.z / b)
    else
        return Vec3:new(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

-- ---Floor division operator
-- ---@param a Vec3
-- ---@param b number|Vec3
-- ---@return Vec3
-- Vec3.__idiv = function(a, b)
--     if type(b) == 'number' then
--         return Vec3:new(a.x // b, a.y // b, a.z // b)
--     else
--         return Vec3:new(a.x // b.x, a.y // b.y, a.z // b.z)
--     end
-- end

---Modulo operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__mod = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x % b, a.y % b, a.z % b)
    else
        return Vec3:new(a.x % b.x, a.y % b.y, a.z % b.z)
    end
end

---Negation operator
---@param a Vec3
---@return Vec3
function Vec3.__unm(a)
    return Vec3:new(-a.x, -a.y, -a.z)
end

---Power operator
---@param a Vec3
---@param b number|Vec3
---@return Vec3
Vec3.__pow = function(a, b)
    if type(b) == 'number' then
        return Vec3:new(a.x ^ b, a.y ^ b, a.z ^ b)
    else
        return Vec3:new(a.x ^ b.x, a.y ^ b.y, a.z ^ b.z)
    end
end

---Length of Vec3. Will always be 3.
---@return integer
Vec3.__len = function()
    return 3
end

---Equality operator overload
---@param a Vec3
---@param b Vec3
---@return boolean
Vec3.__eq = function(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

---Assign index operator
---@param a Vec3
---@param key integer must be 1, 2 or 3
---@param value number
Vec3.__newindex = function(a, key, value)
    if key == 1 then
        a.x = value
    elseif key == 2 then
        a.y = value
    elseif key == 3 then
        a.z = value
    end
end

---String conversion overload
---@param a Vec3
---@return string
Vec3.__tostring = function(a)
    return 'Vec3(' .. a.x .. ', ' .. a.y .. ', ' .. a.z .. ')'
end

---Get the length squared of this Vec3. This function is faster than the
---Vec3.get_length function and is useful for comparing two relative vectors.
---@return number
function Vec3:get_length2()
    if self.x == 0 and self.y == 0 and self.z == 0 then
        return 0
    else
        return self.x ^ 2 + self.y ^ 2 + self.z ^ 2
    end
end

---Get the length of this Vec3
---@return number
function Vec3:get_length()
    if self.x == 0 and self.y == 0 and self.z == 0 then
        return 0
    else
        return math.sqrt(self:get_length2())
    end
end

---Adjust x, y and z of this Vec3 to the new length
---@param new_length number
function Vec3:set_length(new_length)
    local length = self:get_length()
    if length == 0 then
        return
    end
    self.x = self.x * new_length / length
    self.y = self.y * new_length / length
    self.z = self.z * new_length / length
end

---TODO angle functions from Vec2

---Get a new vector with length == 1 and a matching angle to this Vec3
---@return Vec3
function Vec3:normalized()
    local new_vec = Vec3:new(self.x, self.y, self.z)
    new_vec:set_length(1)
    return new_vec
end

return {
    Vec2 = Vec2,
    Vec3 = Vec3,
}
