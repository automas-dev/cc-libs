local stack = require 'cc-libs.util.stack'

local s

local test = {}

function test.setup()
    s = stack:new()
end

function test.new()
    s = stack:new()
    expect_eq(0, #s)
end

function test.push()
    s:push(1)
    assert_eq(1, #s)
    expect_eq(1, s[1])

    s:push('a')
    assert_eq(2, #s)
    expect_eq(1, s[1])
    expect_eq('a', s[2])
end

function test.pop()
    s:push('a')
    s:push('b')
    assert_eq(2, #s)

    expect_eq('b', s:pop())
    expect_eq(1, #s)

    expect_eq('a', s:pop())
    expect_eq(0, #s)
end

function test.pop_empty()
    expect_eq(nil, s:pop())
end

function test.peek()
    s:push('a')
    assert_eq(1, #s)

    expect_eq('a', s:peek())

    s:push('b')
    expect_eq(2, #s)

    expect_eq('b', s:peek())
end

function test.peek_empty()
    expect_eq(nil, s:peek())
end

return test
