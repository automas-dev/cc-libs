local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

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
---@return any[] tokens
function TSParser:parse()
    local tokens = self.lexer:tokens()
    -- TODO stuff here
    return tokens
end

return {
    TSParser = TSParser,
}
