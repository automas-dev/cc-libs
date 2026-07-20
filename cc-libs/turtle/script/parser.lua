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

local function is_reserved(tok)
    return tok == '['
        or tok == ']'
        or tok == ';'
        or tok:sub(1, 1) == '$'
        or tok:sub(1, 1) == ':'
        or tok:sub(1, 1) == '?'
end

---Parse text into tokens
---@return TSToken[] tokens
function TSParser:parse()
    ---@type { [string]: TSToken[] }
    local fn_def = {}

    ---@type { fn_name: string?, prog: TSToken[] }[]
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
            table.insert(nest, { prog = prog })
            prog = {}
        elseif tok:sub(1, 1) == '?' then
            assert(#tok > 1, 'missing function name')
            local fn_name = tok:sub(2)
            table.insert(nest, { fn_name = fn_name, prog = prog })
            prog = {}
        elseif tok == ';' then
            assert(#nest > 0, 'Close function but function start not exist')
            local fn_actions = prog
            ---@type { fn_name: string?, prog: TSToken[] }
            local tmp = table.remove(nest)
            local fn_name = tmp.fn_name
            assert(fn_name ~= nil, 'loop not closed before function')
            prog = tmp.prog
            fn_def[fn_name] = fn_actions
        elseif tok:sub(1, 1) == ':' then
            local fn_name = tok:sub(2)
            local fn_actions = fn_def[fn_name]
            assert(fn_actions ~= nil, 'unknown function ' .. tostring(fn_name))
            local num = tonumber(tokens[i + 1])
            if num ~= nil then
                count = num
                i = i + 1
            end

            for _ = 1, count do
                for _, elem in ipairs(fn_actions) do
                    table.insert(prog, elem)
                end
            end
        else
            if self:does_token_take_arg(tok) then
                assert(i < #tokens, 'missing argument for ' .. tostring(tok))
                arg = tokens[i + 1]
                assert(not is_reserved(arg), 'Tried to use reserved token for arg ' .. tostring(arg))
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
    if #nest > 0 then
        if nest[#nest].fn_name ~= nil then
            error('Unclosed function ' .. tostring(nest[#nest].fn_name))
        else
            error('Unclosed loop [')
        end
    end
    return prog
end

return {
    TSParser = TSParser,
}
