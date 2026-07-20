---@diagnostic disable: inject-field, undefined-field
-- luacheck: ignore 143 142

local ccl_location = require 'cc-libs.turtle.location'
local Compass = ccl_location.Compass
local CompassName = ccl_location.CompassName
local Action = ccl_location.Action
local Location = ccl_location.Location
local LocalFrame = ccl_location.LocalFrame

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local test = {}

function test.setup()
    patch('gps')
    -- Patched for logger
    patch('os.epoch').return_value = 0
    patch('os.getComputerID').return_value = 1
    patch('os.getComputerLabel').return_value = 'name'
end

function test.compass()
    expect_eq(1, Compass.NORTH)
    expect_eq(2, Compass.EAST)
    expect_eq(3, Compass.SOUTH)
    expect_eq(4, Compass.WEST)
end

function test.compass_name()
    expect_eq('North', CompassName[Compass.NORTH])
    expect_eq('East', CompassName[Compass.EAST])
    expect_eq('South', CompassName[Compass.SOUTH])
    expect_eq('West', CompassName[Compass.WEST])
end

function test.action()
    expect_eq(1, Action.FORWARD)
    expect_eq(2, Action.BACKWARD)
    expect_eq(3, Action.UP)
    expect_eq(4, Action.DOWN)
    expect_eq(5, Action.TURN_LEFT)
    expect_eq(6, Action.TURN_RIGHT)
end

function test.new()
    local loc = Location:new()

    expect_eq(Vec3:new(0, 0, 0), loc.pos)
    expect_eq(Compass.NORTH, loc.heading)
    expect_false(loc.has_fix)
    expect_false(loc.has_heading)
    expect_false(loc.debug_location)
end

function test.new_with_map()
    local mock_map = Mock()
    local loc = Location:new(mock_map)
    assert_eq(1, #loc.maps)
    expect_eq(mock_map, loc.maps[1])
end

function test.new_with_gps()
    gps.locate.return_unpack = { 1, 2, 3 }
    local loc = Location:new()
    expect_eq(Vec3:new(1, 2, 3), loc.pos)
    expect_true(loc.has_fix)
    expect_false(loc.has_heading)
    gps.locate.assert_called_once_with(0, false)
end

function test.location()
    local loc = Location:new()
    loc.pos = Vec3:new(1, 2, 3)
    loc.heading = Compass.EAST
    local pos, heading = loc:location()
    expect_eq(Vec3:new(1, 2, 3), pos)
    expect_eq(Compass.EAST, heading)
end

function test.heading_name()
    local loc = Location:new()

    loc.heading = Compass.NORTH
    expect_eq(CompassName[Compass.NORTH], loc:heading_name())

    loc.heading = Compass.EAST
    expect_eq(CompassName[Compass.EAST], loc:heading_name())

    loc.heading = Compass.SOUTH
    expect_eq(CompassName[Compass.SOUTH], loc:heading_name())

    loc.heading = Compass.WEST
    expect_eq(CompassName[Compass.WEST], loc:heading_name())
end

function test.delta()
    local loc = Location:new()

    loc.heading = Compass.NORTH
    expect_eq(Vec3:new(0, 0, -1), loc:delta())

    loc.heading = Compass.EAST
    expect_eq(Vec3:new(1, 0, 0), loc:delta())

    loc.heading = Compass.SOUTH
    expect_eq(Vec3:new(0, 0, 1), loc:delta())

    loc.heading = Compass.WEST
    expect_eq(Vec3:new(-1, 0, 0), loc:delta())
end

function test.set_heading_from_delta()
    local loc = Location:new()
    expect_false(loc.has_heading)
    expect_eq(Compass.NORTH, loc.heading)

    loc:set_heading_from_delta(Vec3:new(0, 1, 0))
    expect_false(loc.has_heading)
    expect_eq(Compass.NORTH, loc.heading)

    loc:set_heading_from_delta(Vec3:new(0, -1, 0))
    expect_false(loc.has_heading)
    expect_eq(Compass.NORTH, loc.heading)

    loc:set_heading_from_delta(Vec3:new(1, 0, 0))
    expect_true(loc.has_heading)
    expect_eq(Compass.EAST, loc.heading)

    loc:set_heading_from_delta(Vec3:new(0, 0, 1))
    expect_eq(Compass.SOUTH, loc.heading)

    loc:set_heading_from_delta(Vec3:new(-1, 0, 0))
    expect_eq(Compass.WEST, loc.heading)

    loc:set_heading_from_delta(Vec3:new(0, 0, -1))
    expect_eq(Compass.NORTH, loc.heading)
end

function test.update_acquire_heading_forward()
    local loc = Location:new()

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 1, 0, 0 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.FORWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.EAST, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 0, 0, 1 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.FORWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.SOUTH, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { -1, 0, 0 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.FORWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.WEST, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 0, 0, -1 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.FORWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.NORTH, loc.heading)
end

function test.update_acquire_heading_backward()
    local loc = Location:new()

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { -1, 0, 0 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.BACKWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.EAST, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 0, 0, -1 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.BACKWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.SOUTH, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 1, 0, 0 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.BACKWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.WEST, loc.heading)

    loc.pos = Vec3:new(0, 0, 0)
    gps.locate.return_unpack = { 0, 0, 1 }
    loc.has_fix = true
    loc.has_heading = false
    loc:update(Action.BACKWARD)
    expect_true(loc.has_heading)
    expect_eq(Compass.NORTH, loc.heading)
end

function test.update_forward()
    local loc = Location:new()

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.NORTH
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.FORWARD)
    expect_eq(Vec3:new(0, 0, -1), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.EAST
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.FORWARD)
    expect_eq(Vec3:new(1, 0, 0), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.SOUTH
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.FORWARD)
    expect_eq(Vec3:new(0, 0, 1), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.WEST
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.FORWARD)
    expect_eq(Vec3:new(-1, 0, 0), loc.pos)
end

function test.update_backward()
    local loc = Location:new()

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.NORTH
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.BACKWARD)
    expect_eq(Vec3:new(0, 0, 1), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.EAST
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.BACKWARD)
    expect_eq(Vec3:new(-1, 0, 0), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.SOUTH
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.BACKWARD)
    expect_eq(Vec3:new(0, 0, -1), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.heading = Compass.WEST
    loc.has_fix = true
    loc.has_heading = true
    loc:update(Action.BACKWARD)
    expect_eq(Vec3:new(1, 0, 0), loc.pos)
end

function test.update_up_down()
    local loc = Location:new()

    loc.pos = Vec3:new(0, 0, 0)
    loc.has_fix = true
    loc:update(Action.UP)
    expect_eq(Vec3:new(0, 1, 0), loc.pos)

    loc.pos = Vec3:new(0, 0, 0)
    loc.has_fix = true
    loc:update(Action.DOWN)
    expect_eq(Vec3:new(0, -1, 0), loc.pos)
end

function test.update_turn_left()
    local loc = Location:new()
    loc.heading = Compass.NORTH

    loc:update(Action.TURN_LEFT)
    expect_eq(Compass.WEST, loc.heading)

    loc:update(Action.TURN_LEFT)
    expect_eq(Compass.SOUTH, loc.heading)

    loc:update(Action.TURN_LEFT)
    expect_eq(Compass.EAST, loc.heading)

    loc:update(Action.TURN_LEFT)
    expect_eq(Compass.NORTH, loc.heading)
end

function test.update_turn_right()
    local loc = Location:new()
    loc.heading = Compass.NORTH

    loc:update(Action.TURN_RIGHT)
    expect_eq(Compass.EAST, loc.heading)

    loc:update(Action.TURN_RIGHT)
    expect_eq(Compass.SOUTH, loc.heading)

    loc:update(Action.TURN_RIGHT)
    expect_eq(Compass.WEST, loc.heading)

    loc:update(Action.TURN_RIGHT)
    expect_eq(Compass.NORTH, loc.heading)
end

function test.update_unknown()
    local loc = Location:new()

    local success, _ = pcall(loc.update, loc, 'unknown')
    expect_false(success)
end

function test.update_debug_location()
    local loc = Location:new()
    loc.debug_location = true

    gps.locate.return_unpack = { 0, 0, 0 }
    local success, _ = pcall(loc.update, loc, Action.FORWARD)
    expect_false(success)
end

function test.update_map()
    local mock_map = Mock()
    local loc = Location:new(mock_map)
    loc:update(Action.FORWARD)
    assert_eq(1, mock_map.link.call_count)
    assert_eq(3, #mock_map.link.args)
    expect_eq(mock_map, mock_map.link.args[1])
    expect_eq(Vec3:new(0, 0, 0), mock_map.link.args[2])
    expect_eq(Vec3:new(0, 0, -1), mock_map.link.args[3])
end

function test.frame_new()
    local frame = LocalFrame:new(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Vec3:new(1, 2, 3), frame.origin)
    expect_eq(Compass.EAST, frame.heading)
end

function test.frame_global_to_local()
    local frame = LocalFrame:new(Vec3:new(1, 2, 3))
    local pos, heading = frame:to_local(Vec3:new(4, 4, 4))
    expect_eq(Vec3:new(3, 2, 1), pos)
    expect_eq(Compass.NORTH, heading)
end

function test.frame_global_to_local_north_frame_heading()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.NORTH)
    local _, heading
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Compass.NORTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Compass.EAST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Compass.SOUTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Compass.WEST, heading)
end

function test.frame_global_to_local_north_frame_pos()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.NORTH)
    local pos
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Vec3:new(1, 2, 3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Vec3:new(1, 2, 3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Vec3:new(1, 2, 3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Vec3:new(1, 2, 3), pos)
end

function test.frame_global_to_local_east_frame_heading()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.EAST)
    local _, heading
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Compass.EAST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Compass.SOUTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Compass.WEST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Compass.NORTH, heading)
end

function test.frame_global_to_local_east_frame_pos()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.EAST)
    local pos
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Vec3:new(-3, 2, 1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Vec3:new(-3, 2, 1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Vec3:new(-3, 2, 1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Vec3:new(-3, 2, 1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Vec3:new(-3, 2, 1), pos)
end

function test.frame_global_to_local_south_frame_heading()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.SOUTH)
    local _, heading
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Compass.SOUTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Compass.WEST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Compass.NORTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Compass.EAST, heading)
end

function test.frame_global_to_local_south_frame_pos()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.SOUTH)
    local pos
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Vec3:new(-1, 2, -3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Vec3:new(-1, 2, -3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Vec3:new(-1, 2, -3), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Vec3:new(-1, 2, -3), pos)
end

function test.frame_global_to_local_west_frame_heading()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.WEST)
    local _, heading
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Compass.WEST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Compass.NORTH, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Compass.EAST, heading)
    _, heading = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Compass.SOUTH, heading)
end

function test.frame_global_to_local_west_frame_pos()
    local frame = LocalFrame:new(Vec3:new(0, 0, 0), Compass.WEST)
    local pos
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.NORTH)
    expect_eq(Vec3:new(3, 2, -1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.EAST)
    expect_eq(Vec3:new(3, 2, -1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.SOUTH)
    expect_eq(Vec3:new(3, 2, -1), pos)
    pos = frame:to_local(Vec3:new(1, 2, 3), Compass.WEST)
    expect_eq(Vec3:new(3, 2, -1), pos)
end

return test
