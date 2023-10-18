-- originally from http://stackoverflow.com/questions/6075262/lua-table-tostringtablename-and-table-fromstringstringtable-functions
-- modified fixed a serialization issue with invalid name. and wrap with 2 functions to serialize / deserialize

local serialize = {}

function serialize.dump(table)
    return serialize.table(table)
end

function serialize.load(str)
    local f = load("return" .. str)
    assert(f ~= nil, 'f was nil, not sure why')
    return f()
end

local function testarray(val, fast)
    fast = fast or false
    if fast then
        return val[1] ~= nil
    else
        for k, v in pairs(val) do
            if type(k) ~= "number" then
                return false
            end
        end
        return true
    end
end

function serialize.table(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep(" ", depth)
    if name then
        if not string.match(name, '^[a-zA-z_][a-zA-Z0-9_]*$') then
            name = string.gsub(name, "'", "\\'")
            name = "['" .. name .. "']"
        end
        tmp = tmp .. name .. " = "
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        local isarray = testarray(val)
        for k, v in pairs(val) do
            tmp = tmp .. serialize.table(v, (not isarray and k or nil), skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end

return serialize
