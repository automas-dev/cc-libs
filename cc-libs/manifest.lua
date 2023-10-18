
local filename = 'manifest.csv'

if not fs.exists(filename) then
    local f = io.open(filename, 'w')
    f:close()
end

local function split_line(line, delim)
    for i = 1, #line do
        if line:sub(i, i) == delim then
            local a = line:sub(1, i-1)
            local b = line:sub(i+1, #line)
            return a, b
        end
    end
    return line, nil
end

local t = {}

function init()
    t = {}
    local f = io.open(filename, 'r')
    local line, name, count
    while true do
        line = f:read('*l')
        if not line then break end
        name, count = split_line(line, ',')
        count = tonumber(count)
        t[#t+1] = {name, count}
        -- print('There are '..count..' of "'..name..'"')
    end
    f:close()
end

function index(name)
    -- Returns the index of name or 0 if the entry does not exist
    for i = 1, #t do
        if t[i][1] == name then
            return i
        end
    end
    return 0
end

function get(name, default)
    local i = index(name)
    if i > 0 then
        return t[i][2]
    else
        return default or 0
    end
end

function set(name, count)
    -- Returns true if the entry exists, false if entry was created
    local i = index(name)
    if i > 0 then
        t[i][2] = count
        return true
    else
        t[#t+1] = {name, count}
        return false
    end
end

function inc(name, amount)
    -- Returns true on success, false if entry does not exist
    -- Will not create a new entry if one does not exist
    local i = index(name)
    if i > 0 then
        local count = t[i][2]
        count = count + amount
        t[i][2] = count
        return true
    else
        return false
    end
end


function dec(name, amount)
    -- Returns true on success, false if entry does not exist
    -- Will not create a new entry if one does not exist
    local i = index(name)
    if i > 0 then
        local count = t[i][2]
        count = count - amount
        if count < 0 then
            count = 0
        end
        t[i][2] = count
        return true
    else
        return false
    end
end

function save()
    local f = io.open(filename, 'w')
    for k, v in pairs(t) do
        f:write(v[1]..','..v[2]..'\n')
    end
    f:close()
end

