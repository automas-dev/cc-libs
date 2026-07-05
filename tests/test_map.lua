---@diagnostic disable: inject-field, undefined-field

local ccl_map = require 'cc-libs.map'
local Point = ccl_map.Point
local Map = ccl_map.Map

local vec = require 'cc-libs.util.vec'
local Vec3 = vec.Vec3

local table_size = require 'cc-libs.util.table_size'

local test = {}

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

function test.point_link()
    local p1 = Point:new(1, 0, 0)
    local p2 = Point:new(2, 0, 0)
    local p3 = Point:new(2, 0, 1)

    p1:link(p2, 3)
    assert_eq(1, table_size(p1.links))
    assert_eq(1, table_size(p2.links))
    expect_eq(3, p1.links['2,0,0'])
    expect_eq(3, p2.links['1,0,0'])

    -- Default weight of 1
    p2:link(p3)
    assert_eq(2, table_size(p2.links))
    assert_eq(1, table_size(p3.links))
    expect_eq(1, p2.links['2,0,1'])
    expect_eq(1, p3.links['2,0,0'])
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

    -- TODO everything else
end

return test
