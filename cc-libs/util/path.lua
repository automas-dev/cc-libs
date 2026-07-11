local str = require 'cc-libs.util.string'

local M = {}

---Resolve `path`. If `path` is relative, and `cwd` is not nil, `path` will be
---resolved relative to `cwd`. If `path` is absolute and `cwd` is not nil, `cwd`
---will be ignored.
---@param path string the relative or absolute path to expand
---@param cwd string? if `path` is relative, it will be resolved to absolute relative to `cwd`
---@return string path the resolved relative or absolute path
function M.resolve(path, cwd)
    if path == '/' then
        return path
    end

    if str.ends_with(path, '/') then
        path = path:sub(1, -2)
    end

    local abs = str.starts_with(path, '/')

    if cwd ~= nil and not abs then
        if cwd == '' then
            cwd = '.'
        end
        if cwd ~= '/' and not str.ends_with(cwd, '/') then
            cwd = cwd .. '/'
        end
        path = cwd .. path
        abs = str.starts_with(path, '/')
    end

    local parts = str.split(path, '/')

    local i = 1
    while i <= #parts do
        if (i > 1 and parts[i] == '') or parts[i] == '.' then
            table.remove(parts, i)
        elseif i > 1 and parts[i] == '..' and (parts[i - 1] ~= '..' or abs) then
            table.remove(parts, i)
            if (abs and i > 2) or (not abs and i > 1) then
                table.remove(parts, i - 1)
                i = i - 1
            end
        else
            i = i + 1
        end
    end

    local new_path = table.concat(parts, '/')
    if abs and not str.starts_with(new_path, '/') then
        new_path = '/' .. new_path
    end

    return new_path
end

return M
