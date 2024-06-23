---@meta ccl_map

---@module 'ccl_vec'

local serialize = require 'cc-libs.util.serialize'
local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map')

---@alias PointId string

---Get a string id for the give x, y, z coords of a Point
---@param x number
---@param y number
---@param z number
---@return PointId
local function point_id(x, y, z)
    log:trace('Point id from pos', x, y, z)
    return x .. ',' .. y .. ',' .. z
end

---@class Point
---@field id string
---@field x number
---@field y number
---@field z number
---@field links { [PointId]: number } value is the weight
local Point = {}

---Construct a new Point
---@param x number
---@param y number
---@param z number
---@return Point
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

---Connect this point to another. This will create the link on both points to each other.
---@param other Point point to link with
---@param weight number weight of this link
function Point:link(other, weight)
    weight = weight or 1
    self.links[other.id] = weight
end

---@class Map
---@field graph { [PointId]: Point }
local Map = {
    Point = Point,
}

--- Create a new empty map
function Map:new()
    local o = {
        graph = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Load the map from a file
---@param path string to load from
function Map:load(path)
    log:info('Loading map from', path)

    local file = assert(io.open(path, 'r'))
    local data = serialize.load(file:read('*all'))
    file:close()
    self.graph = data.graph
end

---Write the map to a file
---@param path string file to dump to
function Map:dump(path)
    log:info('Dumping map to', path)

    local file = assert(io.open(path, 'w'))
    file:write(serialize.dump(self))
    file:close()
end

---Check if two points share the same value for at least 2 axis
---@param pos1 vec3|Point
---@param pos2 vec3|Point
---@return boolean
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

---Get a point by it's id
---@param pid PointId
---@return Point
function Map:get(pid)
    log:trace('Get point for id', pid)
    return self.graph[pid]
end

---Get a point by it's components
---@param x number
---@param y number
---@param z number
---@return Point
function Map:point(x, y, z)
    log:trace('Get point for pos', x, y, z)
    local pid = point_id(x, y, z)
    local point = self:get(pid)
    if point == nil then
        point = Point:new(x, y, z)
        self.graph[point.id] = point
    end
    return point
end

---Add two points to the graph and link them. The two points must be inline.
---@param p1 vec3|Point the first point
---@param p2 vec3|Point the second point
function Map:add(p1, p2)
    log:info('Add point', p1.x, p1.y, p1.y, 'and', p2.x, p2.y, p2.z)
    assert(is_inline(p1, p2), 'p1 is not inline with p2')

    local g_p1 = self:point(p1.x, p1.y, p1.z)
    local g_p2 = self:point(p2.x, p2.y, p2.z)
    link_points(g_p1, g_p2)
    link_points(g_p2, g_p1)
end

local M = {
    Point = Point,
    Map = Map,
}

return M
