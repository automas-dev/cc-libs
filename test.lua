local function test_rgps()
    local rgps = require 'cc-libs.turtle.rgps'

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
test_astar()
-- test_map()

print('All tests passed')
