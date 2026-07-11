local function build_str(v, quote_string, comma_space)
    if type(v) == 'table' then
        local keys = {}
        for i, _ in pairs(v) do
            keys[#keys + 1] = i
        end
        -- Put keys in same order every time
        table.sort(keys)
        local lines = {}
        for _, k in ipairs(keys) do
            lines[#lines + 1] = tostring(k) .. '=' .. build_str(v[k], quote_string)
        end
        local sep = comma_space and ', ' or ','
        return '{' .. table.concat(lines, sep) .. '}'
    elseif type(v) == 'function' then
        return '<fn>'
    elseif type(v) == 'string' and quote_string then
        return '"' .. v .. '"'
    end
    return tostring(v)
end

---Build a pretty string for quick printing
---@param t any
---@param quote_string boolean?
---@param comma_space boolean?
---@return string
local function pretty_table(t, quote_string, comma_space)
    assert(type(t) == 'table', 't must be a table')
    return build_str(t, quote_string, comma_space)
end

return pretty_table
