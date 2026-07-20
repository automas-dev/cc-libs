local lexer = require 'cc-libs.turtle.script.lexer'
local parser = require 'cc-libs.turtle.script.parser'

return {
    TSLexer = lexer.TSLexer,
    TSParser = parser.TSParser,
}
