local serialize = require 'cc-libs.serialize'
local logging = require 'cc-libs.logging'
local log = logging.get_logger('map')

local Point = {}

function Point:new(x, y, z)
    local o = {
        id = x .. ',' .. y .. ',' .. z,
        x = x,
        y = y,
        z = z,
        connections = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Connect two points
-- @parm other another Point to connect to
function Point:connect(other)
    if self.connections[other.id] == nil then
        self.connections[other.id] = other
    end
    if other.connections[self.id] == nil then
        other.connections[self.id] = self
    end
end

local M = {
    Point = Point,
}

--- Create a new empty map
function M:new()
    local o = {
        graph = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Load the map from a file
-- @path the file to load from
function M:load(path)
    log:info('Loading map from', path)

    local file = assert(io.open(path, 'r'))
    local data = file:read('*all')
    file:close()
    self.graph = data.graph
end

--- Write the map to a file
-- @path the file to dump to
function M:dump(path)
    log:info('Dumping map to', path)

    local file = assert(io.open(path, 'w'))
    file:write(serialize.dump(self))
    file:close()
end

local function is_inline(pos1, pos2)
    if pos1.x ~= pos2.x then
        return pos1.y == pos2.y and pos1.z == pos2.z
    elseif pos1.y ~= pos2.y then
        return pos1.x == pos2.x and pos1.z == pos2.z
    elseif pos1.z ~= pos2.z then
        return pos1.x == pos2.x and pos1.y == pos2.y
    else
        return true
    end
end

--- Add two points to the graph and connect them.
-- The two points must be inline.
-- @param p1 the first point
-- @param p2 the second point
function M:connect(p1, p2)
    assert(is_inline(p1, p2), 'p1 is not inline with p2')
    log:debug('Connecting', p1.id, 'to', p2.id)

    self.graph[p1.id] = p1
    self.graph[p2.id] = p2

    p1:connect(p2)
end

return M
