local astar = require 'cc-libs.astar'

local nodes = {
    a = {
        x = 0,
        y = 0,
        neighbors = { 'b' },
    },
    b = {
        x = 0,
        y = 3,
        neighbors = { 'a', 'c' },
    },
    c = {
        x = 2,
        y = 3,
        neighbors = { 'b' },
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

local test = {}

function test.astar()
    local path = astar('a', 'c', neighbors, f, h)

    assert_eq(3, #path)
    expect_eq('c', path[1])
    expect_eq('b', path[2])
    expect_eq('a', path[3])
end

return test
