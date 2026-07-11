local M = {}

local function build_str(v, quote_string, comma_space, bracket_space)
    if type(v) == 'table' then
        local keys = {}
        for i, _ in pairs(v) do
            keys[#keys + 1] = i
        end
        -- Put keys in same order every time
        table.sort(keys)
        local lines = {}
        for _, k in ipairs(keys) do
            lines[#lines + 1] = tostring(k) .. '=' .. build_str(v[k], quote_string, comma_space, bracket_space)
        end
        local sep = comma_space and ', ' or ','
        if bracket_space then
            if #lines == 0 then
                return '{ }'
            else
                return '{ ' .. table.concat(lines, sep) .. ' }'
            end
        else
            return '{' .. table.concat(lines, sep) .. '}'
        end
    -- elseif type(v) == 'function' then
    --     return '<fn>'
    elseif type(v) == 'string' and quote_string then
        return '"' .. v .. '"'
    end
    return tostring(v)
end

---Build a pretty string by expanding tables
---@param val any value to stringify
---@param quote_string boolean? string values should be surrounded by double quotes
---@param comma_space boolean? commas are followed by a space
---@param bracket_space boolean? inside of brackets includes a space (eg. {a=1} vs { a=1 })
---@return string string formatted `val`
function M.format(val, quote_string, comma_space, bracket_space)
    if type(val) == 'table' then
        return build_str(val, quote_string, comma_space, bracket_space)
    end
    return tostring(val)
end

---Pretty print using pretty.format for tables
---@param ... any values to print
function M.pprint(...)
    local args = { ... }
    for i, v in ipairs(args) do
        args[i] = M.format(v, true, true, true)
    end
    print(table.concat(args, ' '))
end

return M
