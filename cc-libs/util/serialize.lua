---@meta ccl_serialize

-- originally from http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
-- modified fixed a serialization issue with invalid name. and wrap with 2 functions to serialize / deserialize

---Helper function to test if a value is an array
---@param val any any object or literal
---@return boolean
local function testarray(val)
    for k, _ in pairs(val) do
        if type(k) ~= 'number' then
            return false
        end
    end
    return true
end

local serialize = {}

---Deserialize a string into a table
---@param str string string to deserialize
---@return table
function serialize.load(str)
    local f = load('return' .. str)
    assert(f ~= nil, 'f was nil, not sure why')
    return f()
end

---Serialize a literal, array or table into a string.
---If minimize is false, nested tables will be indented by one space at each level.
---@param val any value or table to serialize
---@param name? string key for current value in table
---@param minimize boolean don't include newlines or indentation to compress the resulting string
---@param depth? number indentation level if minimize is false
---@return string
function serialize.dump(val, name, minimize, depth)
    minimize = minimize or false
    depth = depth or 0

    local pad = ''
    if not minimize then
        pad = string.rep(' ', depth)
    end

    local tmp = pad
    if name then
        if not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
            name = string.gsub(name, '"', '\\"')
            name = '["' .. name .. '"]'
        end
        tmp = tmp .. name .. ' = '
    end

    if type(val) == 'table' then
        tmp = tmp .. '{' .. (not minimize and '\n' or '')

        local isarray = testarray(val)
        for k, v in pairs(val) do
            tmp = tmp
                .. serialize.dump(v,
                    (not isarray and k or nil),
                    minimize,
                    depth + 1)
                .. ','
                .. (not minimize and '\n' or '')
        end

        tmp = tmp .. pad .. '}'
    elseif type(val) == 'number' then
        tmp = tmp .. tostring(val)
    elseif type(val) == 'string' then
        tmp = tmp .. string.format('%q', val)
    elseif type(val) == 'boolean' then
        tmp = tmp .. (val and 'true' or 'false')
    else
        tmp = tmp .. '"[inserializeable datatype:' .. type(val) .. ']"'
    end

    return tmp
end

return serialize
