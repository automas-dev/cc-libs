local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

---@class TSToken
---@field name string
---@field count number number of times to call, default should be 1
---@field arg string? single string argument

---@class TSParser
---@field lexer TSLexer
---@field token_takes_arg string[]
local TSParser = {}

---Create a new Parser object
---@param lexer TSLexer
---@return TSParser
function TSParser:new(lexer)
    local o = {
        lexer = lexer,
        token_takes_arg = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a token which takes an additional argument
---@param name string
function TSParser:takes_arg(name)
    table.insert(self.token_takes_arg, name)
end

---Check if token takes an additional argument
---@param name string
---@return boolean
function TSParser:does_token_take_arg(name)
    for _, t in ipairs(self.token_takes_arg) do
        if t == name then
            return true
        end
    end
    return false
end

---Parse text into tokens
---@return TSToken[] tokens
function TSParser:parse()
    -- TODO stuff here
    ---@type TSToken[][]
    local nest = {}

    ---@type TSToken[]
    local prog = {}

    local tokens = self.lexer:tokens()

    local i = 1
    while i <= #tokens do
        local tok = tokens[i]
        local count = 1
        local arg = nil

        if tok == '[' then
            table.insert(nest, prog)
            prog = {}
        else
            if self:does_token_take_arg(tok) then
                assert(i < #tokens, 'missing argument for ' .. tostring(tok))
                arg = tokens[i + 1]
                i = i + 1
            end

            local num = tonumber(tokens[i + 1])
            if num ~= nil then
                count = num
                i = i + 1
            end

            if tok == ']' then
                assert(#nest > 0, 'Close loop but open does not exist')
                local nest_actions = prog
                prog = table.remove(nest)
                for _ = 1, count do
                    for _, elem in ipairs(nest_actions) do
                        table.insert(prog, elem)
                    end
                end
            else
                table.insert(prog, { name = tok, count = count, arg = arg })
            end
        end
        i = i + 1
    end
    assert(#nest == 0, 'Unclosed loop [')
    return prog
end

return {
    TSParser = TSParser,
}
