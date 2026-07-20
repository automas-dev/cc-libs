local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local Lexer = ccl_ts_lexer.Lexer

local test = {}

function test.lexer_new()
    local text = 'hello world'
    local lexer = Lexer:new(text)
    expect_eq(text, lexer.text)
    expect_eq(1, lexer.i)
    expect_eq(#text, lexer.len)
end

function test.lexer_take_until()
    local lexer = Lexer:new('hello world')
    local a = lexer:take_until(' ')
    expect_eq('hello', a)
    expect_eq(6, lexer.i)
    expect_eq('', lexer:take_until(' '))
    expect_eq(6, lexer.i)
end

function test.lexer_take_while()
    local lexer = Lexer:new('hello world')
    lexer:take_while('h')
    expect_eq(2, lexer.i)
    lexer:take_while('e')
    expect_eq(3, lexer.i)
    lexer:take_while('l')
    expect_eq(5, lexer.i)
end

-- function test.lexer_take_until_any()
--     local lexer = Lexer:new('hello world')
--     local a = lexer:take_until_any({ 'e', 'l' })
--     expect_eq('hello', a)
--     expect_eq(6, lexer.i)
-- end

return test
