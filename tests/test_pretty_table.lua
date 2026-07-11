local pretty_table = require 'cc-libs.util.pretty_table'

local test = {}

function test.single_value()
    expect_eq('{a=1}', pretty_table({ a = 1 }))
    expect_eq('{b=two}', pretty_table({ b = 'two' }))
    expect_eq('{b=true}', pretty_table({ b = true }))
end

function test.quote_string()
    expect_eq('{b="two"}', pretty_table({ b = 'two' }, true))
end

function test.multi_value()
    expect_eq('{a=1,b=two}', pretty_table({ a = 1, b = 'two' }))
end

function test.comma_space()
    expect_eq('{a=1, b=two}', pretty_table({ a = 1, b = 'two' }, false, true))
end

function test.nested()
    expect_eq('{a={b=2,c=three}}', pretty_table({ a = { b = 2, c = 'three' } }))
end

function test.fn()
    expect_eq('{a=<fn>}', pretty_table({ a = function() end }))
end

return test
