local vec = require 'cc-libs.util.vec'
local vec2 = vec.vec2

local test = {}

function test.new()
    local v = vec2:new(1, 2)
    assert_eq(1, v.x)
    assert_eq(2, v.y)
end

function test.new_single()
    local v = vec2:new(3)
    assert_eq(3, v.x)
    assert_eq(3, v.y)
end

function test.new_empty()
    local v = vec2:new()
    assert_eq(0, v.x)
    assert_eq(0, v.y)
end

function test.shorthand()
    local v = vec2(1, 2)
    assert_eq(1, v.x)
    assert_eq(2, v.y)
end

function test.add()
    assert_eq(vec2:new(3, 5), vec2:new(1, 2) + vec2:new(2, 3))
    assert_eq(vec2:new(3, 4), vec2:new(1, 2) + 2)
end

function test.sub()
    assert_eq(vec2:new(1, 2), vec2:new(3, 5) - vec2:new(2, 3))
    assert_eq(vec2:new(3, 4), vec2:new(5, 6) - 2)
end

function test.mul()
    assert_eq(vec2:new(6, 15), vec2:new(3, 5) * vec2:new(2, 3))
    assert_eq(vec2:new(6, 8), vec2:new(3, 4) * 2)
end

function test.div()
    assert_eq(vec2:new(1, 2), vec2:new(2, 8) / vec2:new(2, 4))
    assert_eq(vec2:new(3, 4), vec2:new(6, 8) / 2)
end

-- function test.idiv()
--     assert_eq(vec2:new(1, 2), vec2:new(2, 8) // vec2:new(2, 4))
--     assert_eq(vec2:new(3, 4), vec2:new(6, 8) // 2)
-- end

function test.mod()
    assert_eq(vec2:new(0, 2), vec2:new(2, 5) % vec2:new(2, 3))
    assert_eq(vec2:new(1, 0), vec2:new(3, 4) % 2)
end

function test.unm()
    assert_eq(vec2:new(-1, -2), -vec2:new(1, 2))
end

function test.pow()
    assert_eq(vec2:new(4, 27), vec2:new(2, 3) ^ vec2:new(2, 3))
    assert_eq(vec2:new(25, 36), vec2:new(5, 6) ^ 2)
end

function test.eq()
    assert_true(vec2:new(1, 2) == vec2:new(1, 2))
    assert_true(vec2:new(3) == vec2:new(3))
    assert_true(vec2:new() == vec2:new())
end

function test.len()
    assert_eq(2, #vec2:new(1, 2))
end

function test.index_number()
    local v = vec2:new(3, 4)
    assert_eq(3, v[1])
    assert_eq(4, v[2])
    assert_eq(nil, v[3])
end

function test.index_str()
    local v = vec2:new(3, 4)
    assert_eq(3, v['x'])
    assert_eq(4, v['y'])
    assert_eq(nil, v['z'])
end

function test.newindex_number()
    local v = vec2:new(1, 2)
    v[0] = 2
    v[1] = 3
    v[2] = 4
    v[3] = 5
    assert_eq(3, v[1])
    assert_eq(4, v[2])
end

function test.newindex_str()
    local v = vec2:new(1, 2)
    v['x'] = 3
    v['y'] = 4
    v['z'] = 5
    assert_eq(3, v.x)
    assert_eq(4, v.y)
end

function test.tostring()
    assert_eq('vec2(1, 2)', tostring(vec2:new(1, 2)))
end

function test.get_length2()
    assert_eq(0, vec2:new(0):get_length2())
    assert_eq(5, vec2:new(1, 2):get_length2())
end

function test.get_length()
    assert_float_eq(0, vec2:new(0):get_length())
    assert_float_eq(5, vec2:new(3, 4):get_length())
end

function test.set_length()
    local v = vec2:new(3, 4)
    v:set_length(10)
    assert_float_eq(6, v.x)
    assert_float_eq(8, v.y)
end

function test.rotate()
    local v = vec2:new(3, 4)
    v:rotate(90)
    assert_float_eq(-4, v.x)
    assert_float_eq(3, v.y)
end

function test.rotated()
    local v = vec2:new(3, 4)
    local v2 = v:rotated(90)
    assert_eq(3, v.x)
    assert_eq(4, v.y)
    assert_float_eq(-4, v2.x)
    assert_float_eq(3, v2.y)
end

function test.get_angle()
    local v = vec2:new(3, 4)
    assert_float_eq(53.1301, v:get_angle())
end

function test.get_angle_between()
    local v1 = vec2:new(1, 0)
    local v2 = vec2:new(0, 1)
    assert_float_eq(90, v1:get_angle_between(v2))
end

function test.normalized()
    local v = vec2:new(3, 4)
    local v2 = v:normalized()
    assert_float_eq(0.6, v2.x)
    assert_float_eq(0.8, v2.y)
end

return test
