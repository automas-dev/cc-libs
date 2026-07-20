local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

local ccl_ts_parser = require 'cc-libs.turtle.script.parser'
local TSParser = ccl_ts_parser.TSParser

local test = {}

function test.parser_new()
    local parser = TSParser:new(TSLexer:new('hello "world"'))
    local tokens = parser:parse()
    assert_eq(2, #tokens)
    expect_arr_eq({ name = 'hello' }, tokens[1])
    expect_arr_eq({ name = 'world' }, tokens[1])
end

return test
