local pretty = require 'cc-libs.util.pretty'

local test = {}

function test.format()
    expect_eq('a', pretty.format('a'))
    expect_eq('1', pretty.format(1))
    expect_eq('1', pretty.format(1.0))
    expect_eq('true', pretty.format(true))
    expect_eq('false', pretty.format(false))
    expect_eq('nil', pretty.format(nil))
end

function test.single_value()
    expect_eq('{a=1}', pretty.format({ a = 1 }))
    expect_eq('{b=two}', pretty.format({ b = 'two' }))
    expect_eq('{b=true}', pretty.format({ b = true }))
end

function test.quote_string()
    expect_eq('{b="two"}', pretty.format({ b = 'two' }, true))
end

function test.multi_value()
    expect_eq('{a=1,b=two}', pretty.format({ a = 1, b = 'two' }))
end

function test.comma_space()
    expect_eq('{a=1, b=two}', pretty.format({ a = 1, b = 'two' }, false, true))
end

function test.nested()
    expect_eq('{a={b=2,c=three}}', pretty.format({ a = { b = 2, c = 'three' } }))
end

function test.fn()
    expect_true(string.match(pretty.format({ a = function() end }), '{a=function: 0x%x+}'))
end

function test.pprint()
    local p = patch('print')
    pretty.pprint('hello', { a = 1, b = { c = 'three' } })
    assert_eq(1, p.call_count)
    assert_eq(1, #p.args)
    expect_eq('hello { a=1, b={ c="three" } }', p.args[1])
end

return test
