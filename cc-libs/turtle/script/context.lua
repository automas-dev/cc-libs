local lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = lexer.TSLexer

---@class TSContext
---@field motion Motion
---@field nav Nav
---@field defs table[]
local TSContext = {}

---Create a new TSContext object
---@param motion Motion
---@param nav Nav
---@return TSContext
function TSContext:new(motion, nav)
    local o = {
        motion = motion,
        nav = nav,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function TSContext:evaluate(text) end

return {
    TSContext = TSContext,
}
