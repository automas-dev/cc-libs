---Generate a random id (number)
---@return integer
local function uid()
    -- random number between 1 and int32 max
    return math.random(1, 2147483647)
end

return uid
