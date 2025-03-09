local vec = require 'cc-libs.util.vec'
local vec3 = vec.vec3

local test = {}

function test.new()
    local v = vec3:new(1, 2, 3)
    expect_eq(1, v.x)
    expect_eq(2, v.y)
    expect_eq(3, v.z)
end

function test.new_two()
    expect_false(pcall(function() vec3:new(1, 2) end))
end

function test.new_single()
    local v = vec3:new(3)
    expect_eq(3, v.x)
    expect_eq(3, v.y)
    expect_eq(3, v.z)
end

function test.new_empty()
    local v = vec3:new()
    expect_eq(0, v.x)
    expect_eq(0, v.y)
    expect_eq(0, v.z)
end

function test.shorthand()
    local v = vec3(1, 2, 3)
    expect_eq(1, v.x)
    expect_eq(2, v.y)
    expect_eq(3, v.z)
end

function test.add()
    expect_eq(vec3:new(3, 5, 7), vec3:new(1, 2, 3) + vec3:new(2, 3, 4))
    expect_eq(vec3:new(3, 4, 5), vec3:new(1, 2, 3) + 2)
end

function test.sub()
    expect_eq(vec3:new(1, 2, 3), vec3:new(3, 5, 7) - vec3:new(2, 3, 4))
    expect_eq(vec3:new(3, 4, 5), vec3:new(5, 6, 7) - 2)
end

function test.mul()
    expect_eq(vec3:new(6, 15, 24), vec3:new(3, 5, 6) * vec3:new(2, 3, 4))
    expect_eq(vec3:new(6, 8, 10), vec3:new(3, 4, 5) * 2)
end

function test.div()
    expect_eq(vec3:new(1, 2, 3), vec3:new(2, 8, 15) / vec3:new(2, 4, 5))
    expect_eq(vec3:new(3, 4, 5), vec3:new(6, 8, 10) / 2)
end

-- function test.idiv()
--     expect_eq(vec3:new(1, 2, 3), vec3:new(2, 8, 15) // vec3:new(2, 4, 5))
--     expect_eq(vec3:new(3, 4, 5), vec3:new(6, 8, 10) // 2)
-- end

function test.mod()
    expect_eq(vec3:new(0, 2, 3), vec3:new(2, 5, 3) % vec3:new(2, 3, 6))
    expect_eq(vec3:new(1, 0, 3), vec3:new(1, 4, 3) % 4)
end

function test.unm()
    expect_eq(vec3:new(-1, -2, -3), -vec3:new(1, 2, 3))
end

function test.pow()
    expect_eq(vec3:new(4, 27, 256), vec3:new(2, 3, 4) ^ vec3:new(2, 3, 4))
    expect_eq(vec3:new(25, 36, 49), vec3:new(5, 6, 7) ^ 2)
end

function test.eq()
    expect_true(vec3:new(1, 2, 3) == vec3:new(1, 2, 3))
    expect_true(vec3:new(3) == vec3:new(3))
    expect_true(vec3:new() == vec3:new())
end

function test.len()
    expect_eq(3, #vec3:new(1, 2, 3))
end

function test.index_number()
    local v = vec3:new(3, 4, 5)
    expect_eq(3, v[1])
    expect_eq(4, v[2])
    expect_eq(5, v[3])
    expect_eq(nil, v[4])
end

function test.index_str()
    local v = vec3:new(3, 4, 5)
    expect_eq(3, v['x'])
    expect_eq(4, v['y'])
    expect_eq(5, v['z'])
    expect_eq(nil, v['w'])
end

function test.newindex_number()
    local v = vec3:new(1, 2, 3)
    v[0] = 2
    v[1] = 3
    v[2] = 4
    v[3] = 5
    v[4] = 6
    expect_eq(3, v[1])
    expect_eq(4, v[2])
    expect_eq(5, v[3])
end

function test.newindex_str()
    local v = vec3:new(1, 2, 3)
    v['x'] = 3
    v['y'] = 4
    v['z'] = 5
    v['w'] = 6
    expect_eq(3, v.x)
    expect_eq(4, v.y)
    expect_eq(5, v.z)
end

function test.tostring()
    expect_eq('vec3(1, 2, 3)', tostring(vec3:new(1, 2, 3)))
end

function test.get_length2()
    expect_eq(0, vec3:new(0):get_length2())
    expect_eq(14, vec3:new(1, 2, 3):get_length2())
end

function test.get_length()
    expect_float_eq(0, vec3:new(0):get_length())
    expect_float_eq(7.07106, vec3:new(3, 4, 5):get_length())
end

function test.set_length()
    local v = vec3:new(3, 4, 5)
    v:set_length(10)
    expect_float_eq(4.24264, v.x)
    expect_float_eq(5.65685, v.y)
    expect_float_eq(7.07106, v.z)
end

function test.normalized()
    local v = vec3:new(3, 4, 5)
    local v2 = v:normalized()
    expect_float_eq(0.42426, v2.x)
    expect_float_eq(0.56568, v2.y)
    expect_float_eq(0.70710, v2.z)
end

return test
