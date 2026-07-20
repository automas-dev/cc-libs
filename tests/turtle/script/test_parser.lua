local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

local ccl_ts_parser = require 'cc-libs.turtle.script.parser'
local TSParser = ccl_ts_parser.TSParser

local test = {}

function test.parser_new()
    local lexer = TSLexer:new('hello world')
    local parser = TSParser:new(lexer)
    expect_eq(lexer, parser.lexer)
end

function test.parser_parse_simple()
    local parser = TSParser:new(TSLexer:new('hello "world"'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_takes_arg()
    local parser = TSParser:new(TSLexer:new('hello world'))
    parser:takes_arg('hello')
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq('world', tokens[1].arg)
end

function test.parser_parse_count()
    local parser = TSParser:new(TSLexer:new('hello 2 world'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_arg_and_count()
    local parser = TSParser:new(TSLexer:new('hello world 2'))
    parser:takes_arg('hello')
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq('world', tokens[1].arg)
end

function test.parser_parse_single_loop()
    local parser = TSParser:new(TSLexer:new('[ hello ] world'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_loop()
    local parser = TSParser:new(TSLexer:new('[ hello ] 2 world'))
    local tokens = parser:parse()
    assert_eq(3, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq('hello', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)

    expect_eq('world', tokens[3].name)
    expect_eq(1, tokens[3].count)
    expect_eq(nil, tokens[3].arg)
end

function test.parser_parse_nested_loop()
    local parser = TSParser:new(TSLexer:new('[ [ hello ] 2 world ] 2'))
    local tokens = parser:parse()
    assert_eq(6, #tokens)

    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq('hello', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)

    expect_eq('world', tokens[3].name)
    expect_eq(1, tokens[3].count)
    expect_eq(nil, tokens[3].arg)

    expect_eq('hello', tokens[4].name)
    expect_eq(1, tokens[4].count)
    expect_eq(nil, tokens[4].arg)

    expect_eq('hello', tokens[5].name)
    expect_eq(1, tokens[5].count)
    expect_eq(nil, tokens[5].arg)

    expect_eq('world', tokens[6].name)
    expect_eq(1, tokens[6].count)
    expect_eq(nil, tokens[6].arg)
end

return test
