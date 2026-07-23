local ccl_vec = require 'cc-libs.util.vec'
local Vec2 = ccl_vec.Vec2

local test = {}

function test.new()
    local v = Vec2:new(1, 2)
    expect_eq(1, v.x)
    expect_eq(2, v.y)
end

function test.new_single()
    local v = Vec2:new(3)
    expect_eq(3, v.x)
    expect_eq(3, v.y)
end

function test.new_empty()
    local v = Vec2:new()
    expect_eq(0, v.x)
    expect_eq(0, v.y)
end

function test.shorthand()
    local v = Vec2(1, 2)
    expect_eq(1, v.x)
    expect_eq(2, v.y)
end

function test.add()
    expect_eq(Vec2:new(3, 5), Vec2:new(1, 2) + Vec2:new(2, 3))
    expect_eq(Vec2:new(3, 4), Vec2:new(1, 2) + 2)
end

function test.sub()
    expect_eq(Vec2:new(1, 2), Vec2:new(3, 5) - Vec2:new(2, 3))
    expect_eq(Vec2:new(3, 4), Vec2:new(5, 6) - 2)
end

function test.mul()
    expect_eq(Vec2:new(6, 15), Vec2:new(3, 5) * Vec2:new(2, 3))
    expect_eq(Vec2:new(6, 8), Vec2:new(3, 4) * 2)
end

function test.div()
    expect_eq(Vec2:new(1, 2), Vec2:new(2, 8) / Vec2:new(2, 4))
    expect_eq(Vec2:new(3, 4), Vec2:new(6, 8) / 2)
end

-- function test.idiv()
--     expect_eq(Vec2:new(1, 2), Vec2:new(2, 8) // Vec2:new(2, 4))
--     expect_eq(Vec2:new(3, 4), Vec2:new(6, 8) // 2)
-- end

function test.mod()
    expect_eq(Vec2:new(0, 2), Vec2:new(2, 5) % Vec2:new(2, 3))
    expect_eq(Vec2:new(1, 0), Vec2:new(3, 4) % 2)
end

function test.unm()
    expect_eq(Vec2:new(-1, -2), -Vec2:new(1, 2))
end

function test.pow()
    expect_eq(Vec2:new(4, 27), Vec2:new(2, 3) ^ Vec2:new(2, 3))
    expect_eq(Vec2:new(25, 36), Vec2:new(5, 6) ^ 2)
end

function test.eq()
    expect_true(Vec2:new(1, 2) == Vec2:new(1, 2))
    expect_true(Vec2:new(3) == Vec2:new(3))
    expect_true(Vec2:new() == Vec2:new())
end

function test.len()
    expect_eq(2, #Vec2:new(1, 2))
end

function test.index_number()
    local v = Vec2:new(3, 4)
    expect_eq(3, v[1])
    expect_eq(4, v[2])
    expect_eq(nil, v[3])
end

function test.index_str()
    local v = Vec2:new(3, 4)
    expect_eq(3, v['x'])
    expect_eq(4, v['y'])
    expect_eq(nil, v['z'])
end

function test.newindex_number()
    local v = Vec2:new(1, 2)
    v[0] = 2
    v[1] = 3
    v[2] = 4
    v[3] = 5
    expect_eq(3, v[1])
    expect_eq(4, v[2])
end

function test.newindex_str()
    local v = Vec2:new(1, 2)
    v['x'] = 3
    v['y'] = 4
    v['z'] = 5
    expect_eq(3, v.x)
    expect_eq(4, v.y)
end

function test.tostring()
    expect_eq('Vec2(1, 2)', tostring(Vec2:new(1, 2)))
end

function test.get_length2()
    expect_eq(0, Vec2:new(0):get_length2())
    expect_eq(5, Vec2:new(1, 2):get_length2())
end

function test.get_length()
    expect_float_eq(0, Vec2:new(0):get_length())
    expect_float_eq(5, Vec2:new(3, 4):get_length())
end

function test.set_length()
    local v = Vec2:new(3, 4)
    v:set_length(10)
    expect_float_eq(6, v.x)
    expect_float_eq(8, v.y)
end

function test.rotate()
    local v = Vec2:new(3, 4)
    v:rotate(90)
    expect_float_eq(-4, v.x)
    expect_float_eq(3, v.y)
end

function test.rotated()
    local v = Vec2:new(3, 4)
    local v2 = v:rotated(90)
    expect_eq(3, v.x)
    expect_eq(4, v.y)
    expect_float_eq(-4, v2.x)
    expect_float_eq(3, v2.y)
end

function test.get_angle()
    local v = Vec2:new(3, 4)
    expect_float_eq(53.1301, v:get_angle())
end

function test.get_angle_between()
    local v1 = Vec2:new(1, 0)
    local v2 = Vec2:new(0, 1)
    expect_float_eq(90, v1:get_angle_between(v2))
end

function test.normalized()
    local v = Vec2:new(3, 4)
    local v2 = v:normalized()
    expect_float_eq(0.6, v2.x)
    expect_float_eq(0.8, v2.y)
end

return test
