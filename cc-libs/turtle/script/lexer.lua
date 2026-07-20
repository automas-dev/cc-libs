---@class TSLexer
---@field text string
---@field i number
---@field len number
local TSLexer = {}

---Create a new Lexer object
---@return TSLexer
function TSLexer:new(text)
    local o = {
        text = text,
        i = 1,
        len = #text,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Get text starting at i
---@private
---@param i number
---@return string
function TSLexer:sub(i)
    return self.text:sub(i)
end

---Check if str exists at position i in text
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

---Take characters until a value
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
function TSLexer:take_ws()
    local i = self.i
    while i <= self.len do
        if not self:match_any_at(i, { ' ', '\t', '\r', '\n' }) then
            break
        end
        i = i + 1
    end
    self.i = i
end

---Take characters that are a decimal digit
---@return string value
function TSLexer:take_decimal()
    local i = self.i
    while i <= self.len do
        if not self:match_any_at(i, { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9' }) then
            break
        end
        i = i + 1
    end
    local text = self.text:sub(self.i, i - 1)
    self.i = i
    return text
end

---Take characters that make a number. This can start with a - for negative and include on . for floats
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

return {
    TSLexer = TSLexer,
}
