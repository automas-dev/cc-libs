local vec = require 'cc-libs.util.vec'
local vec3 = vec.vec3

local test = {}

function test.new()
    local v = vec3:new(1, 2, 3)
    assert_eq(1, v.x)
    assert_eq(2, v.y)
    assert_eq(3, v.z)
end

function test.new_two()
    assert_false(pcall(function() vec3:new(1, 2) end))
end

function test.new_single()
    local v = vec3:new(3)
    assert_eq(3, v.x)
    assert_eq(3, v.y)
    assert_eq(3, v.z)
end

function test.new_empty()
    local v = vec3:new()
    assert_eq(0, v.x)
    assert_eq(0, v.y)
    assert_eq(0, v.z)
end

function test.shorthand()
    local v = vec3(1, 2, 3)
    assert_eq(1, v.x)
    assert_eq(2, v.y)
    assert_eq(3, v.z)
end

function test.add()
    assert_eq(vec3:new(3, 5, 7), vec3:new(1, 2, 3) + vec3:new(2, 3, 4))
    assert_eq(vec3:new(3, 4, 5), vec3:new(1, 2, 3) + 2)
end

function test.sub()
    assert_eq(vec3:new(1, 2, 3), vec3:new(3, 5, 7) - vec3:new(2, 3, 4))
    assert_eq(vec3:new(3, 4, 5), vec3:new(5, 6, 7) - 2)
end

function test.mul()
    assert_eq(vec3:new(6, 15, 24), vec3:new(3, 5, 6) * vec3:new(2, 3, 4))
    assert_eq(vec3:new(6, 8, 10), vec3:new(3, 4, 5) * 2)
end

function test.div()
    assert_eq(vec3:new(1, 2, 3), vec3:new(2, 8, 15) / vec3:new(2, 4, 5))
    assert_eq(vec3:new(3, 4, 5), vec3:new(6, 8, 10) / 2)
end

-- function test.idiv()
--     assert_eq(vec3:new(1, 2, 3), vec3:new(2, 8, 15) // vec3:new(2, 4, 5))
--     assert_eq(vec3:new(3, 4, 5), vec3:new(6, 8, 10) // 2)
-- end

function test.mod()
    assert_eq(vec3:new(0, 2, 3), vec3:new(2, 5, 3) % vec3:new(2, 3, 6))
    assert_eq(vec3:new(1, 0, 3), vec3:new(1, 4, 3) % 4)
end

function test.unm()
    assert_eq(vec3:new(-1, -2, -3), -vec3:new(1, 2, 3))
end

function test.pow()
    assert_eq(vec3:new(4, 27, 256), vec3:new(2, 3, 4) ^ vec3:new(2, 3, 4))
    assert_eq(vec3:new(25, 36, 49), vec3:new(5, 6, 7) ^ 2)
end

function test.eq()
    assert_true(vec3:new(1, 2, 3) == vec3:new(1, 2, 3))
    assert_true(vec3:new(3) == vec3:new(3))
    assert_true(vec3:new() == vec3:new())
end

function test.len()
    assert_eq(3, #vec3:new(1, 2, 3))
end

function test.index_number()
    local v = vec3:new(3, 4, 5)
    assert_eq(3, v[1])
    assert_eq(4, v[2])
    assert_eq(5, v[3])
    assert_eq(nil, v[4])
end

function test.index_str()
    local v = vec3:new(3, 4, 5)
    assert_eq(3, v['x'])
    assert_eq(4, v['y'])
    assert_eq(5, v['z'])
    assert_eq(nil, v['w'])
end

function test.newindex_number()
    local v = vec3:new(1, 2, 3)
    v[0] = 2
    v[1] = 3
    v[2] = 4
    v[3] = 5
    v[4] = 6
    assert_eq(3, v[1])
    assert_eq(4, v[2])
    assert_eq(5, v[3])
end

function test.newindex_str()
    local v = vec3:new(1, 2, 3)
    v['x'] = 3
    v['y'] = 4
    v['z'] = 5
    v['w'] = 6
    assert_eq(3, v.x)
    assert_eq(4, v.y)
    assert_eq(5, v.z)
end

function test.tostring()
    assert_eq('vec3(1, 2, 3)', tostring(vec3:new(1, 2, 3)))
end

function test.get_length2()
    assert_eq(0, vec3:new(0):get_length2())
    assert_eq(14, vec3:new(1, 2, 3):get_length2())
end

function test.get_length()
    assert_float_eq(0, vec3:new(0):get_length())
    assert_float_eq(7.07106, vec3:new(3, 4, 5):get_length())
end

function test.set_length()
    local v = vec3:new(3, 4, 5)
    v:set_length(10)
    assert_float_eq(4.24264, v.x)
    assert_float_eq(5.65685, v.y)
    assert_float_eq(7.07106, v.z)
end

function test.normalized()
    local v = vec3:new(3, 4, 5)
    local v2 = v:normalized()
    assert_float_eq(0.42426, v2.x)
    assert_float_eq(0.56568, v2.y)
    assert_float_eq(0.70710, v2.z)
end

return test
