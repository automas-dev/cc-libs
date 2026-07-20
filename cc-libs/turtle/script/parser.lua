local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

---@class TSToken
---@field name string

---@class TSParser
---@field lexer TSLexer
local TSParser = {}

---Create a new Parser object
---@param lexer TSLexer
---@return TSParser
function TSParser:new(lexer)
    local o = {
        lexer = lexer,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Parse text into tokens
---@return TSToken[] tokens
function TSParser:parse()
    -- TODO stuff here
    local tokens = self.lexer:tokens()
    for i, token in ipairs(tokens) do
        tokens[i] = { name = token }
    end
    return tokens
end

return {
    TSParser = TSParser,
}
