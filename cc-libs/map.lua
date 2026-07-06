local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map')

local json = require 'cc-libs.util.json'

local table_size = require 'cc-libs.util.table_size'

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

---@alias PointId string

---Get a string id for the give x, y, z coords of a Point
---@param x number
---@param y number
---@param z number
---@return PointId
local function point_id(x, y, z)
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
        -- TODO vec instead of x, y, z
        x = x,
        y = y,
        z = z,
        links = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Create a Point from a Vec3
---@param vec Vec3
---@return Point
function Point:from_vec3(vec)
    return Point:new(vec.x, vec.y, vec.z)
end

---Convert Point to a Vec3
---@return Vec3
function Point:to_vec3()
    return Vec3:new(self.x, self.y, self.z)
end

---Connect this point to another. This will create the link on both points to each other.
---@param other Point point to link with
---@param weight? number weight of this link
function Point:link(other, weight)
    weight = weight or 1
    self.links[other.id] = weight
    if other.links[self.id] == nil then
        other:link(self, weight)
    end
end

---Check if another point is inline with one of this points axis (ie. 2 axes match)
---@param other Vec3|Point
---@return boolean
function Point:inline(other)
    if self.x ~= other.x then
        return self.y == other.y and self.z == other.z
    elseif self.y ~= other.y then
        return self.x == other.x and self.z == other.z
    elseif self.z ~= other.z then
        return self.x == other.x and self.y == other.y
    else
        return true
    end
end

---String conversion overload
function Point:__tostring()
    return 'Point(id="'
        .. self.id
        .. '",x='
        .. self.x
        .. ',y='
        .. self.y
        .. ',z='
        .. self.z
        .. ',#links='
        .. table_size(self.links)
        .. ')'
end

---@class Map
---@field graph { [PointId]: Point }
local Map = {}

--- Create a new empty map
---@return Map
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
    ---@diagnostic disable-next-line: param-type-mismatch
    local data = json.decode(file:read('*all'))
    file:close()
    self.graph = data.graph
end

---Write the map to a file
---@param path string file to dump to
function Map:dump(path)
    log:info('Dumping map to', path)

    local file = assert(io.open(path, 'w'))
    file:write(json.encode(self))
    file:close()
end

---Get a point by it's id
---@param pid PointId
---@return Point
function Map:get(pid)
    return self.graph[pid]
end

---Get a point by it's components
---@param x number
---@param y number
---@param z number
---@return Point
function Map:point(x, y, z)
    local pid = point_id(x, y, z)
    local point = self:get(pid)
    if point == nil then
        log:trace('Creating point for id', pid)
        point = Point:new(x, y, z)
        self.graph[point.id] = point
    else
        log:trace('Got point', point, 'for id', pid)
    end
    return point
end

---Add two points to the graph and link them. The two points must be inline.
---@param p1 Vec3|Point the first point
---@param p2 Vec3|Point the second point
---@param weight? number weight of the link
function Map:add(p1, p2, weight)
    log:debug('Add point', p1, 'and', p2)

    -- Get by x, y, z instead of id to support vec and auto-add missing points
    local g_p1 = self:point(p1.x, p1.y, p1.z)
    local g_p2 = self:point(p2.x, p2.y, p2.z)

    if weight == nil then
        weight = (g_p1:to_vec3() - g_p2:to_vec3()):get_length()
    end

    assert(g_p1:inline(g_p2), 'p1 is not inline with p2')

    -- Creates link in both directions
    g_p1:link(g_p2, weight)

    self:link_adjacent(g_p1)
    self:link_adjacent(g_p2)

    -- TODO check for points between p1 and p2

    log:trace('p1 becomes', g_p1, 'p2 becomes', g_p2)
end

---Link adjacent points if they exist
---@param point Point
function Map:link_adjacent(point)
    local p

    -- +x
    p = self:get(point_id(point.x + 1, point.y, point.z))
    if p ~= nil then
        point:link(p, 1)
    end
    -- -x
    p = self:get(point_id(point.x - 1, point.y, point.z))
    if p ~= nil then
        point:link(p, 1)
    end

    -- +y
    p = self:get(point_id(point.x, point.y + 1, point.z))
    if p ~= nil then
        point:link(p, 1)
    end
    -- -y
    p = self:get(point_id(point.x, point.y - 1, point.z))
    if p ~= nil then
        point:link(p, 1)
    end

    -- +z
    p = self:get(point_id(point.x, point.y, point.z + 1))
    if p ~= nil then
        point:link(p, 1)
    end
    -- -z
    p = self:get(point_id(point.x, point.y, point.z - 1))
    if p ~= nil then
        point:link(p, 1)
    end
end

local M = {
    Point = Point,
    Map = Map,
}

return M
