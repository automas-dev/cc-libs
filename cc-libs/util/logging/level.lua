---@enum LogLevel
local Level = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    FATAL = 5,
}

local M = {
    Level = Level,
}

---Get the string name of a level
---@param level number|LogLevel level or level number
---@return string
function M.level_name(level)
    assert(level >= 0, 'level must be a positive number')
    if level == Level.TRACE then
        return 'trace'
    elseif level == Level.DEBUG then
        return 'debug'
    elseif level == Level.INFO then
        return 'info'
    elseif level == Level.WARNING then
        return 'warning'
    elseif level == Level.ERROR then
        return 'error'
    elseif level == Level.FATAL then
        return 'fatal'
    else
        return 'custom:' .. tostring(level)
    end
end

---Get the level from it's string name
---@param name string name of the level
---@return LogLevel? level number
function M.level_from_name(name)
    name = name:lower()
    if name == 'trace' then
        return Level.TRACE
    elseif name == 'debug' then
        return Level.DEBUG
    elseif name == 'info' then
        return Level.INFO
    elseif name == 'warning' then
        return Level.WARNING
    elseif name == 'error' then
        return Level.ERROR
    elseif name == 'fatal' then
        return Level.FATAL
    end
end

return M
