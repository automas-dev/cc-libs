local M = {}

---Check if `text` starts with `match`
---@param text string string to check
---@param match string expected start of `text`
---@return boolean
function M.starts_with(text, match)
    return text:sub(1, #match) == match
end

---Check if `text` ends with `match`
---@param text string string to check
---@param match string expected end of `text`
---@return boolean
function M.ends_with(text, match)
    return text:sub(-#match) == match
end

---Split a string on `sep` starting from the beginning of `text`
---@param text string text to split
---@param sep string? separator to split `text` on, default ' '
---@param max_count number? max number of splits (eg, 1 would return 2 strings)
---@return string[] split strings
function M.split(text, sep, max_count)
    if sep == nil then
        sep = ' '
    end
    if #text == 0 then
        return { '' }
    end
    local t = {}
    while #text > 0 do
        local i = 1
        while i <= #text and not M.starts_with(text:sub(i), sep) do
            i = i + 1
        end
        table.insert(t, text:sub(1, i - 1))
        if text:sub(i) == sep then
            table.insert(t, '')
            break
        end
        i = i + #sep
        text = text:sub(i)
        if max_count and #text > 0 and #t >= max_count then
            table.insert(t, text)
            break
        end
    end
    return t
end

---Split a string on `sep` starting from the end of `text`
---@param text string text to split
---@param sep string? separator to split `text` on, default ' '
---@param max_count number? max number of splits (eg, 1 would return 2 strings)
---@return string[] split strings
function M.rsplit(text, sep, max_count)
    local p = M.split(text, sep, nil)
    if max_count == nil then
        return p
    end
    local t = {}
    while #p > 0 and #t < max_count do
        table.insert(t, 1, table.remove(p))
    end
    if #p > 0 then
        table.insert(t, 1, table.concat(p, sep))
    end
    return t
end

return M
