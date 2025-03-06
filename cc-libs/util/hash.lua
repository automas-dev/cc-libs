-- https://gist.github.com/scheler/26a942d34fb5576a68c111b05ac3fabe

---Generate a hash for the given string
---@param str string
---@return number
local function hash(str)
    if type(str) ~= 'string' then
        str = tostring(str)
    end

    local h = 5381

    for c in str:gmatch '.' do
        h = ((h << 5) + h) + string.byte(c)
    end

    return h
end

return hash
