local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('nav')

local ccl_map = require 'cc-libs.map'
local Point = ccl_map.Point
local Map = ccl_map.Point

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

---@class Nav
---@field map Map
---@field location Location
---@field poi { [string]: PointId }
local Nav = {}

---Create a new navigation controller
---@param map Map map to store paths, will create new if nil
---@param location Location
---@return Nav
function Nav:new(map, location)
    local o = {
        map = map,
        location = location,
        poi = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a point of interest
---@param name string
---@param point? Point
---@return PointId? previous point id of `name`
function Nav:mark_poi(name, point)
    if point == nil then
        point = self.map:pos(self.location.pos)
    end
    local previous = self.poi[name]
    self.poi[name] = point.id
    log:info('Mark poi', name, point.id)
    return previous
end

---Add a point of interest
---@param name string
---@return PointId? previous point id of `name`
function Nav:clear_poi(name)
    local previous = self.poi[name]
    self.poi[name] = nil
    log:info('Cleared poi', name)
    return previous
end

---Get a point of interest
---@param name string
---@return Point?
function Nav:get_poi(name)
    return self.map:get_point(self.poi[name])
end

---Mark the current location as resume poi
function Nav:mark_resume()
    self:mark_poi('resume')
end

---Find a path from start to goal
---@param start_poi_name string
---@param goal_poi_name string
---@return Point[] path from start to goal
function Nav:find_path(start_poi_name, goal_poi_name)
    local start = self:get_poi(start_poi_name)
    assert(start ~= nil, 'Missing start poi ' .. start_poi_name)

    local goal = self:get_poi(goal_poi_name)
    assert(goal ~= nil, 'Missing goal poi ' .. goal_poi_name)

    local path = self.map:find_path(start, goal)
    assert(path ~= nil, 'Failed to find path from ' .. tostring(start) .. ' to ' .. tostring(goal))
    return path
end

local M = {
    Nav = Nav,
}

return M
