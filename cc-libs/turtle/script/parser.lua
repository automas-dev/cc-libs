local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('turtle.script.parser')

local ccl_ts_lexer = require 'cc-libs.turtle.script.lexer'
local TSLexer = ccl_ts_lexer.TSLexer

---@enum TSTokenType
local TSTokenType = {
    CALL = 'call',
    DEF = 'def',
    BLOCK = 'block',
    ASSIGN = 'assign', -- #name
    VAR = 'var', -- $name
    VALUE = 'value', -- arg value
}

---@class TSToken
---@field type TSTokenType
---@field name string?
---@field count number|string number of times to call or string symbol, defaults to 1
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

local function is_reserved(lex, tok)
    for _, sym in ipairs(lex.symbols) do
        if tok == sym then
            return true
        end
    end
    -- return tok == '['
    --     or tok == ']'
    --     or tok == ';'
    --     or tok:sub(1, 1) == '#'
    --     or tok:sub(1, 1) == '$'
    --     or tok:sub(1, 1) == ':'
    --     or tok:sub(1, 1) == '?'
    --     or tok:sub(1, 1) == '!'
    --     or tok:sub(1, 1) == '<'
end

local function is_closing(tok)
    return tok == ']' or tok == ';'
end

---@param lex TSLexer
---@return TSToken token
function TSParser:parse_fn_def(lex)
    assert(lex:take_token() == ':', 'Lexer is not at a function definition')

    local fn_name = lex:take_token()
    assert(fn_name ~= nil and #fn_name >= 1, 'missing function name')
    assert(not is_reserved(lex, fn_name), 'reserved token used as function name ' .. tostring(fn_name))

    local fn_ast = self:parse_block(lex)
    assert(lex:peek_token() == ';', 'Function was never closed')

    return { type = TSTokenType.DEF, name = fn_name, count = 1, children = fn_ast }
end

---@param lex TSLexer
---@return TSToken token
function TSParser:parse_load_script(lex)
    assert(lex:take_token() == '<', 'Lexer is not at a script load')

    local path = lex:take_token()
    assert(path ~= nil and #path >= 1, 'missing path')

    local file = assert(io.open(path, 'r'))
    log:debug('Loading script from', path)

    local script_text = file:read('a')
    file:close()

    local sub_ast = self:parse(script_text)
    log:debug('sub program is', sub_ast)

    return { type = TSTokenType.BLOCK, count = 1, children = sub_ast }
end

---@param lex TSLexer
---@return TSToken token
function TSParser:parse_call(lex)
    local token = lex:take_token()
    assert(token ~= nil)
    assert(not is_reserved(lex, token))

    local count = 1
    local arg = nil

    if self:does_token_take_arg(token) then
        arg = lex:take_token()
        assert(arg ~= nil, 'missing argument for ' .. tostring(token))
        assert(not is_reserved(lex, arg), 'Tried to use reserved token for arg ' .. tostring(arg))
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

    return { type = TSTokenType.CALL, name = token, count = count, arg = arg }
end

---Parse text into tokens
---@param lex TSLexer
---@return TSToken token
function TSParser:parse_token(lex)
    local token = lex:peek_token()
    ---@cast token string

    ---@type TSToken
    local parsed_token

    if token == '[' then
        lex:take_token()
        local block_ast = self:parse_block(lex)
        assert(lex:take_token() == ']', 'unclosed loop')
        parsed_token = { type = TSTokenType.BLOCK, children = block_ast, count = 1 }
    elseif type(token) == 'string' and #token > 1 and token:sub(1, 1) == ':' then
        error('Old format function def')
    elseif token == ':' then
        parsed_token = self:parse_fn_def(lex)
        assert(lex:take_token() == ';', 'unclosed function')
    elseif token == ';' then
        error('function close before open')
    elseif type(token) == 'string' and #token > 1 and token:sub(1, 1) == '<' then
        error('Old format script load')
    elseif token == '<' then
        parsed_token = self:parse_load_script(lex)
    else
        parsed_token = { type = TSTokenType.CALL, name = token, count = 1 }
        lex:take_token()
    end

    if self:does_token_take_arg(token) then
        parsed_token.arg = lex:take_token()
        assert(parsed_token.arg ~= nil, 'missing argument for ' .. tostring(token))
        assert(
            not is_reserved(lex, parsed_token.arg),
            'Tried to use reserved token for arg ' .. tostring(parsed_token.arg)
        )
    end

    local peek = lex:peek_token() or ''
    local num = tonumber(peek)
    if num ~= nil then
        parsed_token.count = num
        lex:take_token()
    elseif peek == '?' or peek == '!' or peek:sub(1, 1) == '$' or peek:sub(1, 1) == '#' then
        ---@diagnostic disable-next-line: cast-local-type
        parsed_token.count = peek
        lex:take_token()
    end

    return parsed_token
end

---Parse text into tokens
---@param lex TSLexer
---@return TSToken[] tokens
function TSParser:parse_block(lex)
    ---@type TSToken[]
    local ast = {}

    local last_i = lex.i
    while lex:peek_token() and not is_closing(lex:peek_token()) do
        local node = self:parse_token(lex)

        -- Expand blocks that don't loop (eg loading a script)
        if node.type == TSTokenType.BLOCK and node.count == 1 then
            for _, n in ipairs(node.children) do
                table.insert(ast, n)
            end
        else
            table.insert(ast, node)
        end

        if lex.i == last_i and lex.i <= lex.len then
            error('Parse loop detected')
        end
    end

    return ast
end

---Parse text into tokens
---@param text string
---@return TSToken[] tokens
function TSParser:parse(text)
    local lex = TSLexer:new(text)
    return self:parse_block(lex)
end

return {
    TSParser = TSParser,
    TSTokenType = TSTokenType,
}
