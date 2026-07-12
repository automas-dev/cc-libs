local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('nav')

local ccl_location = require 'cc-libs.turtle.location'
local Compass = ccl_location.Compass
local CompassName = ccl_location.CompassName

local json = require 'cc-libs.util.json'

---@class Nav
---@field map Map
---@field motion Motion
---@field poi { [string]: PointId }
local Nav = {}

---Create a new navigation controller
---@param map Map map to store paths, will create new if nil
---@param motion Motion turtle motion controller with location
---@return Nav
function Nav:new(map, motion)
    local o = {
        map = map,
        motion = motion,
        -- Keeping these separate from the map waypoints because they are more temporary
        poi = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a point of interest using motion location if point is nil
---@param name string name of the point of interest
---@param point? Point point or nil to use motion location
function Nav:mark_poi(name, point)
    if point == nil then
        point = self.map:pos(self.motion.location.pos)
    end
    self.poi[name] = point.id
    log:info('Mark poi', name, point.id)
end

---Mark the current location as `resume` poi using motion location
function Nav:mark_resume()
    self:mark_poi('resume')
end

---Add a point of interest from a map waypoint
---@param name string name of the waypoint
function Nav:poi_from_waypoint(name)
    self:mark_poi(name, self.map:get_waypoint(name))
end

---Copy a point of interest to the map as a waypoint
---@param name string name of the point of interest
function Nav:poi_to_waypoint(name)
    local point = self:get_poi(name)
    if point ~= nil then
        self.map:add_waypoint(point, name)
    end
end

---Get the map `Point` for a point of interest
---@param name string name of the point of interest
---@return Point? point point from map if `name` exists
function Nav:get_poi(name)
    local pid = self.poi[name]
    if pid ~= nil then
        return self.map:get_point(pid)
    end
end

---Remove a point of interest
---@param name string
---@return PointId? previous point id of `name`
function Nav:clear_poi(name)
    local previous = self.poi[name]
    self.poi[name] = nil
    log:info('Cleared poi', name)
    return previous
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

---Follow a path of map points
---@param path Point[]
function Nav:follow_path(path)
    assert(#path > 1, 'Not enough points in path')
    assert(path[1]:to_vec3() == self.motion.location.pos, 'Path does not start at current location')

    local f = fs.open('path.json', 'w')
    if f ~= nil then
        f.write(json.encode(path))
        f.close()
    end

    local actions = {}

    local last_direction = nil

    for i = 2, #path do
        local from = path[i - 1]
        local to = path[i]

        if from.x ~= to.x then
            local delta = math.abs(to.x - from.x)
            local direction = from.x < to.x and Compass.EAST or Compass.WEST
            if direction ~= last_direction then
                actions[#actions + 1] = {
                    action = 'face',
                    direction = direction,
                    direction_name = CompassName[direction],
                }
                last_direction = direction
            end
            actions[#actions + 1] = {
                action = 'forward',
                count = delta,
            }
        elseif from.y ~= to.y then
            local delta = math.abs(to.y - from.y)
            actions[#actions + 1] = {
                action = from.y < to.y and 'up' or 'down',
                count = delta,
            }
        elseif from.z ~= to.z then
            local delta = math.abs(to.z - from.z)
            local direction = from.z < to.z and Compass.SOUTH or Compass.NORTH
            if direction ~= last_direction then
                actions[#actions + 1] = {
                    action = 'face',
                    direction = direction,
                    direction_name = CompassName[direction],
                }
                last_direction = direction
            end
            actions[#actions + 1] = {
                action = 'forward',
                count = delta,
            }
        end
    end

    log:debug('Path of length', #path, 'results in', #actions, 'actions')

    f = fs.open('motion_actions.json', 'w')
    if f ~= nil then
        f.write(json.encode(actions))
        f.close()
    end

    for i, step in ipairs(actions) do
        log:trace('Step', i, 'is', step.action)
        if step.action == 'face' then
            self.motion:face(step.direction)
        elseif step.action == 'up' then
            self.motion:up(step.count)
        elseif step.action == 'down' then
            self.motion:down(step.count)
        elseif step.action == 'forward' then
            self.motion:forward(step.count)
        end
    end
end

local M = {
    Nav = Nav,
}

return M
