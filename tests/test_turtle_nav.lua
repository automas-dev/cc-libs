---@diagnostic disable: inject-field, undefined-field

local ccl_nav = require 'cc-libs.turtle.nav'
local Nav = ccl_nav.Nav

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_map = require 'cc-libs.map'
local Point = ccl_map.Point
local Map = ccl_map.Map

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local table_size = require 'cc-libs.util.table_size'

local test = {}

function test.setup()
    patch('gps')
    -- Patched for logger
    patch('os.epoch').return_value = 0
    patch('os.getComputerID').return_value = 1
    patch('os.getComputerLabel').return_value = 'name'
end

---Create map, location, motion and nav objects
---@param pos Vec3?
---@param heading Compass?
---@return Nav
---@return Map
---@return Location
local function setup_nav(pos, heading)
    local map = Map:new()
    local location = Location:new(map)
    location.has_fix = true
    location.has_heading = true
    if pos ~= nil then
        location.pos = pos
    end
    if heading ~= nil then
        location.heading = heading
    end
    local nav = Nav:new(map, location)
    return nav, map, location
end

function test.nav_new()
    local nav, map, location = setup_nav()

    expect_eq(location, nav.location)
    expect_eq(map, nav.map)
    expect_eq(0, table_size(nav.poi))
end

function test.add_poi()
    local nav = setup_nav()
    local point = Point:new(1, 2, 3)
    nav:add_poi('a', point)
    expect_eq(point.id, nav.poi['a'])
end

function test.add_poi_here()
    local nav = setup_nav(Vec3:new(1, 2, 3))
    nav:add_poi('a')
    local poi = nav.poi['a']
    expect_eq('1,2,3', poi)
end

function test.get_poi()
    local nav, map = setup_nav()
    local point = map:point(1, 2, 3)
    nav.poi['a'] = point.id
    expect_eq(point, nav:get_poi('a'))
end

function test.mark_resume()
    local nav, map = setup_nav(Vec3:new(1, 2, 3))
    local point = map:point(1, 2, 3)
    nav:mark_resume()
    local poi = nav.poi['resume']
    expect_eq(point.id, poi)
end

function test.find_path()
    local nav, map = setup_nav()
    local p1 = map:point(0, 0, 0)
    local p2 = map:point(1, 0, 0)
    local p3 = map:point(1, 1, 0)
    map:add(p1, p2)
    map:add(p2, p3)

    nav:add_poi('start', p1)
    nav:add_poi('goal', p3)

    local path = nav:find_path('start', 'goal')
    assert_ne(nil, path)
    expect_eq(3, #path)
    -- Not part of test, only here for type check on next lines
    assert(path ~= nil)
    expect_eq(p1, path[1])
    expect_eq(p2, path[2])
    expect_eq(p3, path[3])
end

return test
