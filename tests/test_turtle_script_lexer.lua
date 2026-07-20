---@diagnostic disable: invisible

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

function test.lexer_sub()
    local lexer = Lexer:new('hello world')
    expect_eq('hello world', lexer:sub(1))
    expect_eq('ello world', lexer:sub(2))
    expect_eq('d', lexer:sub(11))
    expect_eq('', lexer:sub(12))
    expect_eq('', lexer:sub(13))
end

function test.lexer_match_at()
    local lexer = Lexer:new('hello world')
    expect_true(lexer:match_at(1, 'h'))
    expect_true(lexer:match_at(1, 'he'))
    expect_true(lexer:match_at(1, 'hello world'))

    expect_false(lexer:match_at(2, 'h'))

    expect_true(lexer:match_at(2, 'e'))
    expect_true(lexer:match_at(2, 'el'))
    expect_true(lexer:match_at(2, 'ello world'))
    expect_true(lexer:match_at(11, 'd'))

    expect_false(lexer:match_at(12, 'd'))
end

function test.lexer_match_any_at()
    local lexer = Lexer:new('hello world')
    expect_true(lexer:match_any_at(1, { 'h', 'w' }))
    expect_false(lexer:match_any_at(2, { 'h', 'w' }))
    expect_false(lexer:match_any_at(1, { '1' }))
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

function test.lexer_take_ws()
    local lexer = Lexer:new('h world')
    lexer:take_ws()
    expect_eq(1, lexer.i)

    lexer = Lexer:new(' \t\r\nhello world')
    lexer:take_ws()
    expect_eq(5, lexer.i)
end

function test.lexer_take_number()
    expect_eq('100', Lexer:new('100'):take_number())
    expect_eq('1', Lexer:new('1 2'):take_number())
    expect_eq('1.0', Lexer:new('1.0'):take_number())
    expect_eq('1.2', Lexer:new('1.2'):take_number())
    expect_eq('-3', Lexer:new('-3'):take_number())
    expect_eq('-3.14', Lexer:new('-3.14'):take_number())
end

function test.lexer_take_quoted_string()
    local lexer = Lexer:new('"hello world"')
    local text = lexer:take_quoted_string()
    expect_eq('hello world', text)
    expect_eq(14, lexer.i)
end

function test.lexer_take_quoted_string_with_escape()
    local lexer = Lexer:new('"hello\\"world"')
    local text = lexer:take_quoted_string()
    expect_eq('hello"world', text)
    expect_eq(15, lexer.i)
end

function test.lexer_take_quoted_string_escape_not_quote()
    local lexer = Lexer:new('"hello\\ world"')
    local text = lexer:take_quoted_string()
    expect_eq('hello\\ world', text)
    expect_eq(15, lexer.i)
end

function test.lexer_take_until_any()
    local lexer = Lexer:new('hello world')
    local a = lexer:take_until_any({ 'e', 'l' })
    expect_eq('h', a)
    expect_eq(2, lexer.i)

    lexer = Lexer:new('hello world')
    a = lexer:take_until_any({ 'o', 'l' })
    expect_eq('he', a)
    expect_eq(3, lexer.i)
end

return test
