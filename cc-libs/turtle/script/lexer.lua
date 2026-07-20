---@class Lexer
---@field text string
---@field i number
---@field len number
local Lexer = {}

---Create a new Lexer object
---@return Lexer
function Lexer:new(text)
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
function Lexer:sub(i)
    return self.text:sub(i)
end

---Check if str exists at position i in text
---@param i number
---@param str string
---@return boolean
function Lexer:match_at(i, str)
    local text = self.text:sub(i)
    if #text < #str then
        return false
    end
    if #text > #str then
        text = text:sub(1, #str)
    end
    return text == str
end

---Take characters until a value
---@param value string
---@return string token
function Lexer:take_until(value)
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
function Lexer:take_while(value)
    local i = self.i
    while i <= self.len do
        if not self:match_at(i, value) then
            break
        end
        i = i + 1
    end
    self.i = i
end

-- ---Take characters until a value
-- ---@param values string[]
-- ---@return string token
-- function Lexer:take_until_any(values)
--     local i = self.i
--     while i <= self.len do
--         for _, val in ipairs(values) do
--             if self:match_at(i, val) then
--                 break
--             end
--         end
--         i = i + 1
--     end
--     if i == self.i then
--         return ''
--     end
--     local text = self.text:sub(self.i, i - 1)
--     self.i = i
--     return text
-- end

return {
    Lexer = Lexer,
}
