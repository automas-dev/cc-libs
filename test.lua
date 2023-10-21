local function test_rgps()
    local rgps = require 'cc-libs.rgps'

    local gps = rgps:new()

    gps:up()
    gps:forward()
    gps:face(rgps.Compass.E)
    gps:forward()
    gps:face(rgps.Compass.W)
    gps:forward(2)
    gps:face(rgps.Compass.E)
    gps:forward()
    gps:face(rgps.Compass.N)
    gps:backward()

    print(gps:direction_name())
    print(gps:delta())
    print(gps:location())

    gps:down()
end

local function test_stack()
    local stack = require 'cc-libs.stack'
    local s = stack:new()
    s:push('a')
    s:push('b')
    s:push('c')
    assert(#s == 3)
    assert(s:pop() == 'c')
    assert(s:pop() == 'b')
    assert(s:pop() == 'a')
    assert(#s == 0)
    assert(s:pop() == nil)
end

local function test_queue()
    local queue = require 'cc-libs.queue'
    local q = queue:new()
    q:push('a')
    q:push('b')
    q:push('c')
    assert(#q == 3)
    assert(q:pop() == 'a')
    assert(q:pop() == 'b')
    assert(q:pop() == 'c')
    assert(q:pop() == nil)
    assert(#q == 0)
end

local function test_serialize()
    local s = require 'cc-libs.serialize'
    local a = {
        text = 'a',
        list = { 1, 2, 3 },
        nest = {
            foo = 1,
            bar = {
                baz = 2
            },
        },
    }

    local str = s.dump(a)
    local b = s.load(str)
    assert(a.text == b.text)
    assert(#a.list == #b.list, tostring(#a.list) .. ' ' .. tostring(#b.list))
    assert(a.list[1] == b.list[1])
    assert(a.list[2] == b.list[2])
    assert(a.list[3] == b.list[3])
    assert(a.nest.foo == b.nest.foo)
    assert(a.nest.bar.baz == b.nest.bar.baz)
end

local function test_astar()
    local astar = require 'cc-libs.astar'

    local nodes = {
        a = {
            x = 0,
            y = 0,
            neighbors = { 'b' }
        },
        b = {
            x = 0,
            y = 3,
            neighbors = { 'a', 'c' }
        },
        c = {
            x = 2,
            y = 3,
            neighbors = { 'b' }
        },
    }

    local function f(n1, n2)
        local dx = math.abs(nodes[n1].x - nodes[n2].x)
        local dy = math.abs(nodes[n1].y - nodes[n2].y)
        return dx + dy
    end

    local function h(n1, n2)
        local dx = math.abs(nodes[n1].x - nodes[n2].x)
        local dy = math.abs(nodes[n1].y - nodes[n2].y)
        return math.sqrt(dx * dx + dy * dy)
    end

    local function neighbors(node)
        return nodes[node].neighbors
    end

    local path = astar('a', 'c', neighbors, f, h)

    assert(#path == 3)
    assert(path[1] == 'c')
    assert(path[2] == 'b')
    assert(path[3] == 'a')
end

local function test_map()
    local map = require 'cc-libs.map'

    local m = map:new()
    m.graph[0] = {
        name = 'a',
        place = { 0, 1 }
    }

    m:dump('m.map')
end


-- test_rgps()
test_stack()
test_queue()
test_serialize()
test_astar()
-- test_map()

print('All tests passed')
