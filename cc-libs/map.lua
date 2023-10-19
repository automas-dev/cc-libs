local serialize = require 'cc-libs.serialize'
local logging = require 'cc-libs.logging'
local log = logging.get_logger('map')

local Point = {}

local function point_id(x, y, z)
    return x .. ',' .. y .. ',' .. z
end

function Point:new(x, y, z)
    local o = {
        id = point_id(x, y, z),
        x = x,
        y = y,
        z = z,
        links = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Connect two points
-- @parm other another Point to connect to
function Point:link(other)
    self.links[other.id] = other
    other.links[self.id] = self
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

function M:get_point(x, y, z)
    local pid = point_id(x, y, z)
    local point = self.graph[pid]
    if point == nil then
        point = Point:new(x, y, z)
        self.graph[point.id] = point
    end
    return point
end

--- Add two points to the graph and link them.
-- The two points must be inline.
-- @param p1 the first point vector (x, y, z)
-- @param p2 the second point vector (x, y, z)
function M:add(p1, p2)
    assert(is_inline(p1, p2), 'p1 is not inline with p2')

    local g_p1 = self:get_point(p1.x, p1.y, p1.z)
    local g_p2 = self:get_point(p2.x, p2.y, p2.z)
    g_p1:link(g_p2)
end

return M
