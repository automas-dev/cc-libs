---@class vec2
---@field x number
---@field y number
---@operator add(vec2): vec2
---@operator add(number): vec2
---@operator sub(vec2): vec2
---@operator sub(number): vec2
---@operator mul(vec2): vec2
---@operator mul(number): vec2
---@operator div(vec2): vec2
---@operator div(number): vec2
---@operator mod(vec2): vec2
---@operator mod(number): vec2
---@operator pow(vec2): vec2
---@operator pow(number): vec2
---@operator len(): integer
local vec2 = {
    mt = {}
}
setmetatable(vec2, vec2.mt)

vec2.mt.__call = function(_, x, y)
    return vec2:new(x, y)
end

---Create a new vec2
---@param x? number
---@param y? number
---@return vec2
function vec2:new(x, y)
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

function vec2.__index(a, key)
    if key == 1 then
        return a.x
    elseif key == 2 then
        return a.y
    else
        return vec2[key]
    end
end

---Addition operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__add(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x + b, a.y + b)
    else
        return vec2:new(a.x + b.x, a.y + b.y)
    end
end

---Subtraction operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__sub(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x - b, a.y - b)
    else
        return vec2:new(a.x - b.x, a.y - b.y)
    end
end

---Multiply operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__mul(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x * b, a.y * b)
    else
        return vec2:new(a.x * b.x, a.y * b.y)
    end
end

---Division operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__div(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x / b, a.y / b)
    else
        return vec2:new(a.x / b.x, a.y / b.y)
    end
end

-- ---Floor division operator
-- ---@param a vec2
-- ---@param b number|vec2
-- ---@return vec2
-- function vec2.__idiv(a, b)
--     if type(b) == 'number' then
--         return vec2:new(a.x // b, a.y // b)
--     else
--         return vec2:new(a.x // b.x, a.y // b.y)
--     end
-- end

---Modulo operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__mod(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x % b, a.y % b)
    else
        return vec2:new(a.x % b.x, a.y % b.y)
    end
end

---Negation operator
---@param a vec2
---@return vec2
function vec2.__unm(a)
    return vec2:new(-a.x, -a.y)
end

---Power operator
---@param a vec2
---@param b number|vec2
---@return vec2
function vec2.__pow(a, b)
    if type(b) == 'number' then
        return vec2:new(a.x ^ b, a.y ^ b)
    else
        return vec2:new(a.x ^ b.x, a.y ^ b.y)
    end
end

---Length of vec2. Will always be 2.
---@return integer
function vec2.__len()
    return 2
end

---Equality operator overload
---@param a vec2
---@param b vec2
---@return boolean
function vec2.__eq(a, b)
    return a.x == b.x and a.y == b.y
end

---Assign index operator
---@param a vec2
---@param key integer must be 1 or 2
---@param value number
function vec2.__newindex(a, key, value)
    if key == 1 then
        a.x = value
    elseif key == 2 then
        a.y = value
    end
end

---String conversion overload
---@param a vec2
---@return string
function vec2.__tostring(a)
    return 'vec2(' .. a.x .. ', ' .. a.y .. ')'
end

---Get the length squared of this vec2. This function is faster than the
---vec2.get_length function and is useful for comparing two relative vectors.
---@return number
function vec2:get_length2()
    if self.x == 0 and self.y == 0 then
        return 0
    else
        return self.x ^ 2 + self.y ^ 2
    end
end

---Get the length of this vec2
---@return number
function vec2:get_length()
    if self.x == 0 and self.y == 0 then
        return 0
    else
        return math.sqrt(self:get_length2())
    end
end

---Adjust x and y of this vec2 to the new length
---@param new_length number
function vec2:set_length(new_length)
    local length = self:get_length()
    if length == 0 then
        return
    end
    self.x = self.x * new_length / length
    self.y = self.y * new_length / length
end

---Rotate this vec2 in place
---@param angle_deg number angle in degrees
function vec2:rotate(angle_deg)
    local rad = math.rad(angle_deg)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local new_x = self.x * cos - self.y * sin
    local new_y = self.x * sin + self.y * cos
    self.x = new_x
    self.y = new_y
end

---Return a new vec2 that is rotated by angle_deg. This does not modify self.
---@param angle_deg number angle in degrees
---@return vec2
function vec2:rotated(angle_deg)
    local new_vec = vec2:new(self.x, self.y)
    new_vec:rotate(angle_deg)
    return new_vec
end

---Get the angle in degrees of this vec2
---@return number angle in degrees
function vec2:get_angle()
    if self:get_length() == 0 then
        return 0
    else
        return math.deg(math.atan2(self.y, self.x))
    end
end

---Adjust x and y of this vec2 to the new angle
---@param angle_deg number angle in degrees
function vec2:set_angle(angle_deg)
    self.x = self:get_length()
    self.y = 0
    self:rotate(angle_deg)
end

---Get the angle between two vec2s
---@param other vec2
---@return number angle in degrees
function vec2:get_angle_between(other)
    local cross = self.x * other.y - self.y * other.x
    local dot = self.x * other.x + self.y * other.y
    return math.deg(math.atan2(cross, dot))
end

---Get a new vector with length == 1 and a matching angle to this vec2
---@return vec2
function vec2:normalized()
    local new_vec = vec2:new(self.x, self.y)
    new_vec:set_length(1)
    return new_vec
end

---@class vec3
---@field x number
---@field y number
---@field z number
---@operator add(vec3): vec3
---@operator add(number): vec3
---@operator sub(vec3): vec3
---@operator sub(number): vec3
---@operator mul(vec3): vec3
---@operator mul(number): vec3
---@operator div(vec3): vec3
---@operator div(number): vec3
---@operator mod(vec3): vec3
---@operator mod(number): vec3
---@operator pow(vec3): vec3
---@operator pow(number): vec3
---@operator len(): integer
local vec3 = {
    mt = {}
}
setmetatable(vec3, vec3.mt)

vec3.mt.__call = function(_, x, y, z)
    return vec3:new(x, y, z)
end


---Create a new vec3
---@param x? number
---@param y? number
---@param z? number
---@return vec3
function vec3:new(x, y, z)
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

vec3.__index = function(a, key)
    if key == 1 then
        return a.x
    elseif key == 2 then
        return a.y
    elseif key == 3 then
        return a.z
    else
        return vec3[key]
    end
end

---Addition operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__add = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x + b, a.y + b, a.z + b)
    else
        return vec3:new(a.x + b.x, a.y + b.y, a.z + b.z)
    end
end

---Subtraction operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__sub = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x - b, a.y - b, a.z - b)
    else
        return vec3:new(a.x - b.x, a.y - b.y, a.z - b.z)
    end
end

---Multiply operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__mul = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x * b, a.y * b, a.z * b)
    else
        return vec3:new(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

---Division operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__div = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x / b, a.y / b, a.z / b)
    else
        return vec3:new(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

-- ---Floor division operator
-- ---@param a vec3
-- ---@param b number|vec3
-- ---@return vec3
-- vec3.__idiv = function(a, b)
--     if type(b) == 'number' then
--         return vec3:new(a.x // b, a.y // b, a.z // b)
--     else
--         return vec3:new(a.x // b.x, a.y // b.y, a.z // b.z)
--     end
-- end

---Modulo operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__mod = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x % b, a.y % b, a.z % b)
    else
        return vec3:new(a.x % b.x, a.y % b.y, a.z % b.z)
    end
end

---Negation operator
---@param a vec3
---@return vec3
function vec3.__unm(a)
    return vec3:new(-a.x, -a.y, -a.z)
end

---Power operator
---@param a vec3
---@param b number|vec3
---@return vec3
vec3.__pow = function(a, b)
    if type(b) == 'number' then
        return vec3:new(a.x ^ b, a.y ^ b, a.z ^ b)
    else
        return vec3:new(a.x ^ b.x, a.y ^ b.y, a.z ^ b.z)
    end
end

---Length of vec3. Will always be 3.
---@return integer
vec3.__len = function()
    return 3
end

---Equality operator overload
---@param a vec3
---@param b vec3
---@return boolean
vec3.__eq = function(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

---Assign index operator
---@param a vec3
---@param key integer must be 1, 2 or 3
---@param value number
vec3.__newindex = function(a, key, value)
    if key == 1 then
        a.x = value
    elseif key == 2 then
        a.y = value
    elseif key == 3 then
        a.z = value
    end
end

---String conversion overload
---@param a vec3
---@return string
vec3.__tostring = function(a)
    return 'vec3(' .. a.x .. ', ' .. a.y .. ', ' .. a.z .. ')'
end

---Get the length squared of this vec3. This function is faster than the
---vec3.get_length function and is useful for comparing two relative vectors.
---@return number
function vec3:get_length2()
    if self.x == 0 and self.y == 0 and self.z == 0 then
        return 0
    else
        return self.x ^ 2 + self.y ^ 2 + self.z ^ 2
    end
end

---Get the length of this vec3
---@return number
function vec3:get_length()
    if self.x == 0 and self.y == 0 and self.z == 0 then
        return 0
    else
        return math.sqrt(self:get_length2())
    end
end

---Adjust x, y and z of this vec3 to the new length
---@param new_length number
function vec3:set_length(new_length)
    local length = self:get_length()
    if length == 0 then
        return
    end
    self.x = self.x * new_length / length
    self.y = self.y * new_length / length
    self.z = self.z * new_length / length
end

---TODO angle functions from vec2

---Get a new vector with length == 1 and a matching angle to this vec3
---@return vec3
function vec3:normalized()
    local new_vec = vec3:new(self.x, self.y, self.z)
    new_vec:set_length(1)
    return new_vec
end

return {
    vec2 = vec2,
    vec3 = vec3,
}
