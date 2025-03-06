local queue = require 'cc-libs.util.queue'

local q

local test = {}

function test.setup()
    q = queue:new()
end

function test.new()
    q = queue:new()
    expect_eq(0, #q)
end

function test.push()
    q:push(1)
    assert_eq(1, #q)
    expect_eq(1, q[1])

    q:push('a')
    assert_eq(2, #q)
    expect_eq(1, q[1])
    expect_eq('a', q[2])
end

function test.pop()
    q:push('a')
    q:push('b')
    assert_eq(2, #q)

    expect_eq('a', q:pop())
    expect_eq(1, #q)

    expect_eq('b', q:pop())
    expect_eq(0, #q)
end

function test.pop_empty()
    expect_eq(nil, q:pop())
end

function test.peek()
    q:push('a')
    assert_eq(1, #q)

    expect_eq('a', q:peek())

    q:push('b')
    expect_eq(2, #q)

    expect_eq('a', q:peek())
end

function test.peek_empty()
    expect_eq(nil, q:peek())
end

return test
