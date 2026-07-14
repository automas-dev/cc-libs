-- TODO test
---Return a deep copy of t
---@param t table
---@return table copy
local function table_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            copy[k] = table_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

return table_copy
