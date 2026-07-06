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
---@param point Point?
---@return PointId? previous point id of `name`
function Nav:mark_poi(name, point)
    if point == nil then
        point = self.map:point_from_vec3(self.location.pos)
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
    return self.map:get(self.poi[name])
end

---Mark the current location as resume poi
function Nav:mark_resume()
    self:mark_poi('resume')
end

---Find a path from start to goal
---@param start_poi_name string
---@param goal_poi_name string
---@return Point[]? path from start to goal
function Nav:find_path(start_poi_name, goal_poi_name)
    local start = self:get_poi(start_poi_name)
    assert(start ~= nil, 'Missing start poi ' .. start_poi_name)

    local goal = self:get_poi(goal_poi_name)
    assert(goal ~= nil, 'Missing goal poi ' .. goal_poi_name)

    return self.map:find_path(start, goal)
end

-- ---Move to the trace step
-- ---@param step Vec3 position to move to
-- function Nav:trace_step(step)
--     log:debug('trace step to pos', step.x, step.y, step.z)
--     local pos = self.gps.pos
--     assert(is_inline(pos, step), 'Step is not inline with current position')
--     log:trace('trace starts at pos', pos.x, pos.y, pos.z)

--     if pos.x ~= step.x then
--         local delta = math.abs(step.x - pos.x)

--         if pos.x < step.x then
--             self:face(Compass.EAST)
--         else
--             self:face(Compass.WEST)
--         end

--         self.motion:forward(delta)
--     elseif pos.y ~= step.y then
--         local delta = math.abs(step.y - pos.y)

--         if pos.y < step.y then
--             self.motion:up(delta)
--         else
--             self.motion:down(delta)
--         end
--     elseif pos.z ~= step.z then
--         local delta = math.abs(step.z - pos.z)

--         if pos.z < step.z then
--             self:face(Compass.NORTH)
--         else
--             self:face(Compass.SOUTH)
--         end
--         self.motion:forward(delta)
--     end

--     local end_pos = self.gps.pos
--     local at_end_pos = end_pos.x == step.x and end_pos.y == step.y and end_pos.z == step.z

--     assert(at_end_pos, 'trace_step did not reach step position')
-- end

-- function Nav:follow()
--     log:info('Going to resume point')
--     assert(self.resume ~= nil, 'No resume point is marked')
--     assert(self.gps.pos == self.station, 'Not aligned with trace start')

--     local path = self:find_path(self.station, self.resume)

--     log:debug('Path has', #path, 'points')

--     for i = 1, #path do
--         self:trace_step(path[i])
--     end
-- end

-- function Nav:back_follow()
--     log:info('Going to station point')
--     assert(self.resume ~= nil, 'No resume point is marked')
--     assert(self.gps.pos == self.resume, 'Not aligned with trace end')

--     local path = self:find_path(self.resume, self.station)

--     log:debug('Path has', #path, 'points')

--     for i = 1, #path do
--         self:trace_step(path[i])
--     end
-- end

local M = {
    Nav = Nav,
}

return M
