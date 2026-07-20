local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

local ccl_ts_parser = require 'cc-libs.turtle.script.parser'
local TSParser = ccl_ts_parser.TSParser
local TSTokenType = ccl_ts_parser.TSTokenType

local test = {}

-- TODO parse errors

function test.parser_new()
    local lexer = TSLexer:new('hello world')
    local parser = TSParser:new(lexer)
    expect_eq(lexer, parser.lexer)
end

function test.parser_parse_simple()
    local parser = TSParser:new(TSLexer:new('hello "world"'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.CALL, tokens[1].type)
    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_takes_arg()
    local parser = TSParser:new(TSLexer:new('hello world'))
    parser:takes_arg('hello')
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq(TSTokenType.CALL, tokens[1].type)
    expect_eq('hello', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq('world', tokens[1].arg)
end

function test.parser_parse_count()
    local parser = TSParser:new(TSLexer:new('hello 2 world'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.CALL, tokens[1].type)
    expect_eq('hello', tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq(nil, tokens[1].arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_arg_and_count()
    local parser = TSParser:new(TSLexer:new('hello world 2'))
    parser:takes_arg('hello')
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq(TSTokenType.CALL, tokens[1].type)
    expect_eq('hello', tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq('world', tokens[1].arg)
end

function test.parser_parse_single_loop()
    local parser = TSParser:new(TSLexer:new('[ hello ] world'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.LOOP, tokens[1].type)
    expect_eq(nil, tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(1, #tokens[1].children)

    local child = tokens[1].children[1]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('hello', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_loop()
    local parser = TSParser:new(TSLexer:new('[ hello ] 2 world'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.LOOP, tokens[1].type)
    expect_eq(nil, tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(1, #tokens[1].children)

    local child = tokens[1].children[1]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('hello', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('world', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_nested_loop()
    local parser = TSParser:new(TSLexer:new('[ [ hello ] 2 world ] 2'))
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq(TSTokenType.LOOP, tokens[1].type)
    expect_eq(nil, tokens[1].name)
    expect_eq(2, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(2, #tokens[1].children)

    local child = tokens[1].children[1]

    expect_eq(TSTokenType.LOOP, child.type)
    expect_eq(nil, child.name)
    expect_eq(2, child.count)
    expect_eq(nil, child.arg)
    assert_ne(nil, child.children)
    expect_eq(1, #child.children)

    child = child.children[1]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('hello', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    child = tokens[1].children[2]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('world', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)
end

function test.parser_parse_function_def_only()
    local parser = TSParser:new(TSLexer:new('?f hello world ;'))
    local tokens = parser:parse()
    assert_eq(1, #tokens)

    expect_eq(TSTokenType.DEF, tokens[1].type)
    expect_eq('f', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(2, #tokens[1].children)
end

function test.parser_parse_function_def()
    local parser = TSParser:new(TSLexer:new('?f hello world ; :f'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.DEF, tokens[1].type)
    expect_eq('f', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(2, #tokens[1].children)

    local child = tokens[1].children[1]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('hello', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    child = tokens[1].children[2]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('world', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('f', tokens[2].name)
    expect_eq(1, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

function test.parser_parse_function_count()
    local parser = TSParser:new(TSLexer:new('?f hello world ; :f 2'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)

    expect_eq(TSTokenType.DEF, tokens[1].type)
    expect_eq('f', tokens[1].name)
    expect_eq(1, tokens[1].count)
    expect_eq(nil, tokens[1].arg)
    assert_ne(nil, tokens[1].children)
    expect_eq(2, #tokens[1].children)

    local child = tokens[1].children[1]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('hello', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    child = tokens[1].children[2]

    expect_eq(TSTokenType.CALL, child.type)
    expect_eq('world', child.name)
    expect_eq(1, child.count)
    expect_eq(nil, child.arg)

    expect_eq(TSTokenType.CALL, tokens[2].type)
    expect_eq('f', tokens[2].name)
    expect_eq(2, tokens[2].count)
    expect_eq(nil, tokens[2].arg)
end

return test
