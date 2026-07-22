---@class TSLexer
---@field text string
---@field i number
---@field len number
---@field whitespace string[]
---@field symbols string[] list of reserved symbols that should be separated from other characters
---@field digits string[] list of decimal numbers
---@field private next_token string?
local TSLexer = {}

---Create a new Lexer object
---@return TSLexer
function TSLexer:new(text)
    local o = {
        text = text,
        i = 1,
        len = #text,
        whitespace = { ' ', '\t', '\r', '\n' },
        symbols = { '[', ']', ':', ';', '!', '?', '<' },
        digits = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' },
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Returns true if there are more characters remaining
---@return boolean
function TSLexer:has_more()
    return self.i <= self.len
end

---Get text starting at i
---@private
---@param i number
---@return string
function TSLexer:sub(i)
    return self.text:sub(i)
end

---Check if str exists at position i in text
---@private
---@param i number
---@param str string
---@return boolean
function TSLexer:match_at(i, str)
    assert(#str > 0)
    local text = self.text:sub(i)
    if #text < #str then
        return false
    end
    if #text > #str then
        text = text:sub(1, #str)
    end
    return text == str
end

---Check if any value in arr exists at position i in text
---@private
---@param i number
---@param arr string[] list of strings to match
---@return boolean
function TSLexer:match_any_at(i, arr)
    local text = self.text:sub(i)
    for _, str in ipairs(arr) do
        if #text >= #str then
            if str == text:sub(1, #str) then
                return true
            end
        end
    end
    return false
end

---Return the character at self.i
---@return string character
function TSLexer:peek_char()
    return self.text:sub(self.i, self.i)
end

---Take a single character
---@return string character
function TSLexer:take_char()
    local char = self.text:sub(self.i, self.i)
    if self.i <= self.len then
        self.i = self.i + 1
    end
    return char
end

---Take characters until a value
---@private
---@param value string
---@return string token
function TSLexer:take_until(value)
    local i = self.i
    while i <= self.len do
        if self:match_at(i, value) then
            break
        end
        i = i + 1
    end
    if i == self.i then
        return ''
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Progress the index while the current character matches value
---@private
---@param value string
function TSLexer:take_while(value)
    local i = self.i
    while i <= self.len do
        if not self:match_at(i, value) then
            break
        end
        i = i + 1
    end
    self.i = i
end

---Progress the index while the current character is whitespace
---@private
function TSLexer:take_ws()
    local i = self.i
    while i <= self.len do
        if not self:match_any_at(i, self.whitespace) then
            break
        end
        i = i + 1
    end
    self.i = i
end

---Take characters until whitespace
---@private
---@return string token
function TSLexer:take_until_ws()
    local i = self.i
    while i <= self.len do
        if self:match_any_at(i, self.whitespace) then
            break
        end
        i = i + 1
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Take characters until whitespace or symbol
---@private
---@return string token
function TSLexer:take_until_symbol_or_ws()
    local i = self.i
    while i <= self.len do
        if self:match_any_at(i, self.whitespace) then
            break
        end
        if self:match_any_at(i, self.symbols) then
            break
        end
        i = i + 1
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Take characters of a symbol
---@private
---@return string token
function TSLexer:take_symbol()
    for _, sym in ipairs(self.symbols) do
        if self:match_at(self.i, sym) then
            local i = self.i
            self.i = self.i + #sym
            self.next_token = self.text:sub(i, self.i - 1)
            return self.next_token
        end
    end
    return ''
end

---Take characters that are a decimal digit
---@private
---@return string value
function TSLexer:take_decimal()
    local i = self.i
    while i <= self.len do
        if not self:match_any_at(i, self.digits) then
            break
        end
        i = i + 1
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Take characters that make a number. This can start with a - for negative and include on . for floats
---@private
---@return string value
function TSLexer:take_number()
    local num = ''
    if self:match_at(self.i, '-') then
        num = '-'
        self.i = self.i + 1
    end
    num = num .. self:take_decimal()
    if self:match_at(self.i, '.') then
        self.i = self.i + 1
        local fraction = self:take_decimal()
        num = num .. '.' .. fraction
    end
    return num
end

---Take characters of a quoted string starting on the opening quote
---@private
---@return string value
function TSLexer:take_quoted_string()
    assert(self:match_at(self.i, '"'))

    self.i = self.i + 1
    local i = self.i
    while i <= self.len do
        if self:match_at(i, '"') and not self:match_at(i - 1, '\\') then
            break
        end
        i = i + 1
    end
    local text = self.text:sub(self.i, i - 1)
    text = text:gsub('\\"', '"')
    self.i = i + 1
    return text
end

---Take characters until a value
---@private
---@param values string[]
---@return string token
function TSLexer:take_until_any(values)
    local i = self.i
    while i <= self.len do
        if self:match_any_at(i, values) then
            break
        end
        i = i + 1
    end
    if i == self.i then
        return ''
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Get the next token
---@return string?
function TSLexer:peek_token()
    if self.next_token == nil then
        self:take_ws()
        if self:has_more() then
            if self:match_at(self.i, '--') then
                self:take_until_any({ '\r', '\n' })
                self:take_ws()
            end
            if self:match_any_at(self.i, self.symbols) then
                self.next_token = self:take_symbol()
            elseif self:match_at(self.i, '"') then
                self.next_token = self:take_quoted_string()
            else
                self.next_token = self:take_until_symbol_or_ws()
            end
        end
    end
    return self.next_token
end

---Get the next token
---@return string?
function TSLexer:take_token()
    self:peek_token()
    local token = self.next_token
    self.next_token = nil
    return token
end

---Return a list of all tokens
---@return fun(): string?
function TSLexer:token_iter()
    return function()
        return self:take_token()
    end
end

---Return a list of all tokens
---@return string[]
function TSLexer:tokens()
    local tokens = {}
    for tok in self:token_iter() do
        table.insert(tokens, tok)
    end
    return tokens
end

return {
    TSLexer = TSLexer,
}
