---@diagnostic disable: inject-field, undefined-field

local ccl_map = require 'cc-libs.map'
local Point = ccl_map.Point
local Map = ccl_map.Map

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local table_size = require 'cc-libs.util.table_size'

local test = {}

---Check two points are linked
---@param p1 Point?
---@param p2 Point?
local function expect_linked(p1, p2, weight)
    if weight == nil then
        weight = 1
    end

    -- Make sure points aren't nil
    assert_ne(nil, p1)
    assert_ne(nil, p2)

    ---@cast p1 Point
    ---@cast p2 Point

    expect_eq(weight, p1.links[p2.id])
    expect_eq(weight, p2.links[p1.id])
end

function test.setup()
    patch('gps')
    -- Patched for logger
    patch('os.epoch').return_value = 0
    patch('os.getComputerID').return_value = 1
    patch('os.getComputerLabel').return_value = 'name'
end

function test.point_new()
    local point = Point:new(1, 2, 3)
    expect_eq(1, point.x)
    expect_eq(2, point.y)
    expect_eq(3, point.z)
    expect_eq('1,2,3', point.id)
    expect_eq(0, table_size(point.links))
end

function test.point_from_vec3()
    local point = Point:from_vec3(Vec3:new(1, 2, 3))
    expect_eq(1, point.x)
    expect_eq(2, point.y)
    expect_eq(3, point.z)
end

function test.point_to_vec3()
    local point = Point:new(1, 2, 3)
    expect_eq(Vec3:new(1, 2, 3), point:to_vec3())
end

function test.point_link()
    local p1 = Point:new(1, 0, 0)
    local p2 = Point:new(2, 0, 0)
    local p3 = Point:new(2, 0, 1)

    p1:link(p2, 3)
    expect_linked(p1, p2, 3)

    -- Default weight of 1
    p2:link(p3)
    expect_linked(p2, p3, 1)
end

function test.point_is_inline()
    local point = Point:new(0, 0, 0)
    assert_true(point:inline(Point:new(1, 0, 0)))
    assert_true(point:inline(Point:new(0, 1, 0)))
    assert_true(point:inline(Point:new(0, 0, 1)))

    assert_true(point:inline(Point:new(0, 0, 0)))

    assert_false(point:inline(Point:new(1, 1, 0)))
    assert_false(point:inline(Point:new(1, 0, 1)))
    assert_false(point:inline(Point:new(0, 1, 1)))
    assert_false(point:inline(Point:new(1, 1, 1)))
end

function test.point_to_string()
    local point = Point:new(1, 2, 3)
    expect_eq('Point(id="1,2,3",x=1,y=2,z=3,#links=0)', tostring(point))

    local p2 = Point:new(2, 2, 3)
    point:link(p2)
    expect_eq('Point(id="1,2,3",x=1,y=2,z=3,#links=1)', tostring(point))
    expect_eq('Point(id="2,2,3",x=2,y=2,z=3,#links=1)', tostring(p2))
end

function test.map_new()
    local map = Map:new()
    expect_eq(0, table_size(map.graph))
end

function test.map_load()
    -- TODO
end

function test.map_dump()
    -- TODO
end

function test.map_add_waypoint()
    local map = Map:new()
    map:add_waypoint(Point:new(1, 2, 3), 'poi')
    assert_eq(1, table_size(map.waypoints))
    expect_eq('1,2,3', map.waypoints['poi'])
end

function test.map_get_waypoint()
    local map = Map:new()
    map:point(1, 2, 3)
    map.waypoints['poi'] = '1,2,3'
    local point = map:get_waypoint('poi')
    assert_ne(nil, point)
    ---@diagnostic disable-next-line: need-check-nil
    expect_eq('1,2,3', point.id)
end

function test.map_remove_waypoint()
    local map = Map:new()
    map.waypoints['poi'] = '1,2,3'
    map:remove_waypoint('poi')
    expect_eq(nil, map.waypoints['poi'])
end

function test.map_add_point()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map:add_point(point)
    assert_eq(point, map.graph[point.id])
end

function test.map_get_point()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    assert_eq(point, map:get_point(point.id))
end

function test.map_get_pos()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    assert_eq(point, map:get_pos(1, 2, 3))
end

function test.map_remove_point()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    map:remove_point(point.id)
    assert_eq(nil, map.graph[point.id])
end

function test.map_remove_pos()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    map:remove_pos(1, 2, 3)
    assert_eq(nil, map.graph[point.id])
end

function test.map_point()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    assert_eq(point, map:point(1, 2, 3))
end

function test.map_new_point()
    local map = Map:new()
    local point = map:point(1, 2, 3)
    assert_eq('1,2,3', point.id)
    assert_eq(1, point.x)
    assert_eq(2, point.y)
    assert_eq(3, point.z)
    assert_eq(0, table_size(point.links))
end

function test.map_point_from_vec3()
    local map = Map:new()
    local point = Point:new(1, 2, 3)
    map.graph[point.id] = point
    assert_eq(point, map:point_from_vec3(Vec3:new(1, 2, 3)))
end

function test.map_add()
    local map = Map:new()
    local p1 = Point:new(0, 0, 0)
    local p2 = Point:new(1, 0, 0)

    map:add(p1, p2, 1)

    expect_eq(p1.id, map.graph[p1.id].id)
    expect_eq(p2.id, map.graph[p2.id].id)

    -- p1 and p2 are copied, so they can't be used directly here
    expect_eq(1, map:get_point(p1.id).links[p2.id])
    expect_eq(1, map:get_point(p2.id).links[p1.id])
end

function test.map_add_auto_weight()
    local map = Map:new()
    local p1 = Point:new(0, 0, 0)
    local p2 = Point:new(2, 0, 0)

    map:add(p1, p2)

    expect_eq(p1.id, map.graph[p1.id].id)
    expect_eq(p2.id, map.graph[p2.id].id)

    -- p1 and p2 are copied, so they can't be used directly here
    expect_eq(2, map:get_point(p1.id).links[p2.id])
    expect_eq(2, map:get_point(p2.id).links[p1.id])
end

function test.map_link_adjacent_x()
    local map = Map:new()
    map:point(1, 0, 0)
    map:point(-1, 0, 0)
    map:add(Point:new(0, 1, 0), Point:new(0, 0, 0))

    expect_linked(map:get_point('0,0,0'), map:get_point('1,0,0'), 1)
    expect_linked(map:get_point('0,0,0'), map:get_point('-1,0,0'), 1)
end

function test.map_link_adjacent_y()
    local map = Map:new()
    map:point(0, 1, 0)
    map:point(0, -1, 0)
    map:add(Point:new(1, 0, 0), Point:new(0, 0, 0))

    expect_linked(map:get_point('0,0,0'), map:get_point('0,1,0'), 1)
    expect_linked(map:get_point('0,0,0'), map:get_point('0,-1,0'), 1)
end

function test.map_link_adjacent_z()
    local map = Map:new()
    map:point(0, 0, 1)
    map:point(0, 0, -1)
    map:add(Point:new(1, 0, 0), Point:new(0, 0, 0))

    expect_linked(map:get_point('0,0,0'), map:get_point('0,0,1'), 1)
    expect_linked(map:get_point('0,0,0'), map:get_point('0,0,-1'), 1)
end

function test.map_add_not_inline()
    local map = Map:new()
    local p1 = Point:new(0, 0, 0)
    local p2 = Point:new(1, 1, 0)
    local success = pcall(map.add, map, p1, p2)
    expect_false(success)
end

function test.find_path()
    local map = Map:new()
    local p1 = map:point(0, 0, 0)
    local p2 = map:point(1, 0, 0)
    local p3 = map:point(1, 1, 0)
    map:add(p1, p2)
    map:add(p2, p3)

    -- Path that should not be taken
    local p4 = map:point(2, 0, 0)
    local p5 = map:point(2, 1, 0)
    map:add(p2, p4)
    map:add(p4, p5)
    map:add(p5, p3)

    local path = map:find_path(p1, p3)
    assert_ne(nil, path)
    expect_eq(3, #path)
    -- Not part of test, only here for type check on next lines
    assert(path ~= nil)
    expect_eq(p1, path[1])
    expect_eq(p2, path[2])
    expect_eq(p3, path[3])
end

function test.find_path_no_connection()
    local map = Map:new()
    local p1 = map:point(0, 0, 0)
    local p2 = map:point(1, 1, 0)

    local path = map:find_path(p1, p2)
    expect_eq(nil, path)
end

return test
