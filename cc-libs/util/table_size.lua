---Get the size of a table using pairs
---@param t table
---@return number
local function table_size(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return table_size
