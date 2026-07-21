local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('turtle.script.parser')

local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

---@enum TSTokenType
local TSTokenType = {
    CALL = 'call',
    DEF = 'def',
    BLOCK = 'block',
    ASSIGN = 'assign',
}

---@class TSToken
---@field type TSTokenType
---@field name string
---@field count number|'?' number of times to call, default should be 1
---@field arg string? single string argument
---@field children TSToken[]?

---@class TSParser
---@field lexer TSLexer
---@field token_takes_arg string[]
local TSParser = {}

---Create a new Parser object
---@return TSParser
function TSParser:new()
    local o = {
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
        or tok:sub(1, 1) == '#'
        or tok:sub(1, 1) == '$'
        or tok:sub(1, 1) == ':'
        or tok:sub(1, 1) == '?'
        or tok:sub(1, 1) == '!'
        or tok:sub(1, 1) == '<'
end

---Parse text into tokens
---@param text string
---@return TSToken[] tokens
function TSParser:parse(text)
    local lex = TSLexer:new(text)

    ---@type { fn_name: string?, ast: TSToken[] }[]
    local nest = {}

    ---@type TSToken[]
    local ast = {}

    for token in lex:token_iter() do
        ---@type number|string
        local count = 1
        local arg = nil

        if token == '[' then
            table.insert(nest, { ast = ast })
            ast = {}
        elseif token:sub(1, 1) == ':' then
            local fn_name
            if #token > 1 then
                fn_name = token:sub(2)
            else
                fn_name = lex:take_token()
            end
            assert(fn_name ~= nil and #fn_name >= 1, 'missing function name')
            table.insert(nest, { fn_name = fn_name, ast = ast })
            ast = {}
        elseif token == ';' then
            assert(#nest > 0, 'Close function but function start not exist')
            local fn_actions = ast
            ---@type { fn_name: string?, ast: TSToken[] }
            local tmp = table.remove(nest)
            local fn_name = tmp.fn_name
            assert(fn_name ~= nil, 'loop not closed before function')
            ast = tmp.ast
            table.insert(ast, {
                type = TSTokenType.DEF,
                name = fn_name,
                count = 1,
                children = fn_actions,
            })
        elseif token:sub(1, 1) == '<' then
            local path
            if #token > 1 then
                path = token:sub(2)
            else
                path = lex:take_token()
            end
            assert(path ~= nil and #path >= 1, 'Missing path')
            local file = assert(io.open(path, 'r'))
            log:debug('Loading script from', path)
            local script_text = file:read('a')
            file:close()
            local sub_ast = self:parse(script_text)
            log:debug('sub program is', sub_ast)
            for _, sub_tok in ipairs(sub_ast) do
                table.insert(ast, sub_tok)
            end
        else
            if self:does_token_take_arg(token) then
                arg = lex:take_token()
                assert(arg ~= nil, 'missing argument for ' .. tostring(token))
                assert(not is_reserved(arg), 'Tried to use reserved token for arg ' .. tostring(arg))
            end

            local peek = lex:peek_token() or ''
            local num = tonumber(peek)
            if num ~= nil then
                count = num
                lex:take_token()
            elseif peek == '?' or peek == '!' or peek:sub(1, 1) == '$' or peek:sub(1, 1) == '#' then
                ---@diagnostic disable-next-line: cast-local-type
                count = lex:take_token()
            end

            if token == ']' then
                assert(#nest > 0, 'Close loop but open does not exist')
                local loop_actions = ast
                ast = table.remove(nest).ast
                table.insert(ast, { type = TSTokenType.BLOCK, count = count, children = loop_actions })
            else
                table.insert(ast, { type = TSTokenType.CALL, name = token, count = count, arg = arg })
            end
        end
    end
    if #nest > 0 then
        if nest[#nest].fn_name ~= nil then
            error('Unclosed function ' .. tostring(nest[#nest].fn_name))
        else
            error('Unclosed loop [')
        end
    end
    return ast
end

return {
    TSParser = TSParser,
    TSTokenType = TSTokenType,
}
