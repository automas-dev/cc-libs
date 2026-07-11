---Tokenize text handling quotes
---The characters in sep are treated as independent separators instead of a multi-character separator.
---@param text string
---@param sep string? character separators, default ' \t\r\n'
---@param quotes boolean? allow double quote to combine tokens that would otherwise be separated
---@return string[] tokens
local function tokenize(text, sep, quotes)
    sep = sep or ' \t\r\n'
    local tokens = {}
    while #text > 0 do
        local i = 1
        while i <= #text and text:sub(i, i) == ' ' do
            i = i + 1
        end
        text = text:sub(i)
        i = 1
        local quoted = text:sub(1, 1) == '"'
        if quoted then
            i = i + 1
        end
        while i <= #text and (quoted or text:sub(i, i) ~= ' ') do
            i = i + 1
            if text:sub(i, i) == '"' and text:sub(i - 1, i - 1) ~= '\\' then
                break
            end
        end
        if quoted then
            tokens[#tokens + 1] = text:sub(2, i - 1)
            text = text:sub(i + 1)
        else
            tokens[#tokens + 1] = text:sub(1, i - 1)
            text = text:sub(i)
        end
    end
    return tokens
end

return tokenize
