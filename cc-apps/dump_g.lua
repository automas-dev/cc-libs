package.path = '../?.lua;../?/init.lua;' .. package.path
local json = require 'cc-libs.util.json'

function table.copy(old_t, visited)
    visited = visited or {}
    local new_t = {}
    for k, v in pairs(old_t) do
        print(k)
        if k == '_G' or k == '' then
            print('Skip', k)
        elseif visited[k] ~= nil then
            new_t[k] = 'duplicate'
        else
            visited[k] = true
            if type(v) == 'function' then
                v = 'fun'
            elseif type(v) == 'table' then
                v = table.copy(v, visited)
            else
                v = tostring(v)
            end
            new_t[k] = v
        end
    end
    return new_t
end

local g = table.copy(_G)
g.package = table.copy(_G.package)
print(json.encode(g))

io.open('logs/g.json', 'w'):write(json.encode(g))
