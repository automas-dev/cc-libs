-- https://gist.github.com/scheler/26a942d34fb5576a68c111b05ac3fabe

---Generate a hash for the given string
---@param str string
---@return number
local function hash(str)
    if type(str) ~= 'string' then
        str = tostring(str)
    end

    local h = 5381

    for i = 1, #str do
        h = h * 32 + h + str:byte(i)
    end

    return h
end

return hash
