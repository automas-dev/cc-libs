local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map')

local json = require 'cc-libs.util.json'

local table_copy = require 'cc-libs.util.table_copy'
local table_size = require 'cc-libs.util.table_size'

local astar = require 'cc-libs.astar'

---@alias PointId string

---Get a string id for the give x, y, z coords of a Point
---@param x number
---@param y number
---@param z number
---@return PointId
local function point_id(x, y, z)
    return x .. ',' .. y .. ',' .. z
end

---Check if another point is inline with one of this points axis (ie. 2 axes match)
---@param a Vec3|Point
---@param b Vec3|Point
---@return boolean
local function inline(a, b)
    if a.x ~= b.x then
        return a.y == b.y and a.z == b.z
    elseif a.y ~= b.y then
        return a.x == b.x and a.z == b.z
    elseif a.z ~= b.z then
        return a.x == b.x and a.y == b.y
    else
        return true
    end
end

---Link two Points
---@param p1 Point
---@param p2 Point
---@param weight number
local function link_points(p1, p2, weight)
    if p1.links[p2.id] == nil then
        log:trace('Creating link from', p1.id, 'to', p2.id)
        p1.links[p2.id] = weight
    end
    if p2.links[p1.id] == nil then
        log:trace('Creating link from', p2.id, 'to', p1.id)
        p2.links[p1.id] = weight
    end
end

---Get weight from distance between p1 and p2
---@param p1 Point
---@param p2 Point
---@return number weight
local function point_weight(p1, p2)
    local length2 = (p2.x - p1.x) ^ 2 + (p2.y - p1.y) ^ 2 + (p2.z - p1.z) ^ 2
    return math.sqrt(length2)
end

---@class Point
---@field id string
---@field x number
---@field y number
---@field z number
---@field links { [PointId]: number } value is the weight

---@class Map
---@field graph { [PointId]: Point }
---@field waypoints { [string]: PointId }
local Map = {}

--- Create a new empty map
---@return Map
function Map:new()
    local o = {
        graph = {},
        waypoints = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Load the map from a table
---@param t { graph: table?, waypoints: table?} map data
function Map:from_table(t)
    -- Use default or {} to handle empty graph or waypoints
    if t.graph ~= nil then
        self.graph = t.graph
    end
    if t.waypoints ~= nil then
        self.waypoints = t.waypoints
    end
end

---Load the map from a file
---@param path string to load from
function Map:load(path)
    log:info('Loading map from', path)

    local file = assert(io.open(path, 'r'))
    local data = json.decode(file:read('a'))
    file:close()
    self:from_table(data)
    log:debug('Finished loading map from', path)
end

---Write the map to a file
---@param path string file to dump to
function Map:dump(path)
    log:info('Dumping map to', path)

    local file = assert(io.open(path, 'w'))
    file:write(json.encode(self))
    file:close()
    log:debug('Finished dumping map to', path)
end

-- TODO test
---Return a copy of this map
---@return Map copy
function Map:copy()
    local new = Map:new()
    new.graph = table_copy(self.graph)
    new.waypoints = table_copy(self.waypoints)
    return new
end

---Add a named waypoint, creating point if missing
---@param pos Vec3|Point
---@param name string
function Map:add_waypoint(pos, name)
    local point = self:pos(pos)
    self.waypoints[name] = point.id
end

---Get a named waypoint
---@param name string
---@return Point? point
function Map:get_waypoint(name)
    local pid = self.waypoints[name]
    if pid == nil then
        return nil
    end
    return self:get_point(pid)
end

---Remove a waypoint by name
---@param name string
function Map:remove_waypoint(name)
    self.waypoints[name] = nil
end

---Add a point to the map
---@param point Point
function Map:add_point(point)
    self.graph[point.id] = point
end

---Get a point from it's id
---@param pid PointId
---@return Point?
function Map:get_point(pid)
    return self.graph[pid]
end

---Get a point by location
---@param x number
---@param y number
---@param z number
---@return Point?
function Map:get_pos(x, y, z)
    local pid = point_id(x, y, z)
    return self.graph[pid]
end

---Remove a point using it's id
---@param pid PointId
function Map:remove_point(pid)
    self.graph[pid] = nil
end

---Remove a point by location
---@param x number
---@param y number
---@param z number
function Map:remove_pos(x, y, z)
    local pid = point_id(x, y, z)
    self.graph[pid] = nil
end

---Get or create a point by it's components
---@param x number
---@param y number
---@param z number
---@return Point
function Map:point(x, y, z)
    local point = self:get_pos(x, y, z)
    if point == nil then
        point = {
            id = point_id(x, y, z),
            x = x,
            y = y,
            z = z,
            links = {},
        }
        self.graph[point.id] = point
        -- TODO test this link
        self:link_adjacent(point)
        log:trace('Created point', point)
    else
        log:trace('Got existing point', point)
    end
    return point
end

---Get or create a point by Vec3 position
---@param pos Vec3|Point
---@return Point
function Map:pos(pos)
    return self:point(pos.x, pos.y, pos.z)
end

---Link two points to the graph. The two points must be inline.
---@param p1 Vec3|Point the first point
---@param p2 Vec3|Point the second point
function Map:link(p1, p2)
    -- Get by x, y, z instead of id to support vec and auto-add missing points
    p1 = self:pos(p1)
    p2 = self:pos(p2)
    local weight = point_weight(p1, p2)

    log:debug('p1 =', p1.id, 'p2 =', p2.id, 'weight =', weight)

    assert(inline(p1, p2), 'p1 is not inline with p2')

    link_points(p1, p2, weight)

    self:link_adjacent(p1)
    self:link_adjacent(p2)
end

---Link adjacent points if they exist
---@param point Point
function Map:link_adjacent(point)
    local p

    -- +x
    p = self:get_pos(point.x + 1, point.y, point.z)
    if p ~= nil then
        link_points(point, p, 1)
    end
    -- -x
    p = self:get_pos(point.x - 1, point.y, point.z)
    if p ~= nil then
        link_points(point, p, 1)
    end

    -- +y
    p = self:get_pos(point.x, point.y + 1, point.z)
    if p ~= nil then
        link_points(point, p, 1)
    end
    -- -y
    p = self:get_pos(point.x, point.y - 1, point.z)
    if p ~= nil then
        link_points(point, p, 1)
    end

    -- +z
    p = self:get_pos(point.x, point.y, point.z + 1)
    if p ~= nil then
        link_points(point, p, 1)
    end
    -- -z
    p = self:get_pos(point.x, point.y, point.z - 1)
    if p ~= nil then
        link_points(point, p, 1)
    end
end

---Find a path between two points
---@param p1 Point
---@param p2 Point
---@return Point[]? path array of points in order from p1 to p2
function Map:find_path(p1, p2)
    log:debug('Searching for path between', p1, 'and', p2)

    local function neighbors(pid)
        local point = self:get_point(pid)
        assert(point ~= nil)
        log:trace('neighbors', pid, table_size(point.links))
        return point.links
    end

    local function f(n1, n2)
        log:trace('f n1=', n1, 'n2=', n2)
        local dx = math.abs(self:get_point(n1).x - self:get_point(n2).x)
        local dy = math.abs(self:get_point(n1).y - self:get_point(n2).y)
        return dx + dy
    end

    local function h(n1, n2)
        log:trace('h n1=', n1, 'n2=', n2)
        local dx = math.abs(self:get_point(n1).x - self:get_point(n2).x)
        local dy = math.abs(self:get_point(n1).y - self:get_point(n2).y)
        return math.sqrt(dx * dx + dy * dy)
    end

    local path = astar(p1.id, p2.id, neighbors, f, h, true)
    if path == nil then
        log:error('Failed to find path from', p1, 'to', p2)
        return nil
    end
    log:debug('Path completed with', #path, 'points')

    local path_points = {}
    for i = 1, #path do
        path_points[i] = self:get_point(path[i])
    end

    return path_points
end

return {
    Map = Map,
}
