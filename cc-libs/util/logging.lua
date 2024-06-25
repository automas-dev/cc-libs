---@meta ccl_logging

---@enum LogLevel
local Level = {
    DISABLED = nil,
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    fatal = 5,
}

---Get the string name of a level
---@param level number|LogLevel level or level number
---@return string
local function level_name(level)
    assert(level >= 0, 'level must be a positive number')
    if level == nil then
        return 'disabled'
    elseif level == Level.TRACE then
        return 'trace'
    elseif level == Level.DEBUG then
        return 'debug'
    elseif level == Level.INFO then
        return 'info'
    elseif level == Level.WARNING then
        return 'warning'
    elseif level == Level.ERROR then
        return 'error'
    elseif level == Level.fatal then
        return 'fatal'
    else
        return 'custom:' .. tostring(level)
    end
end

---Get a string timestamp for the current time
---@return string
local function timestamp()
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%Y-%m-%dT%H:%M:%S')
end

---@class Logger
---@field subsystem string
---@field level number|LogLevel
---@field file_level number|LogLevel
---@field file? string active log file path if _file is not nil
---@field _file? file*
---@field _subsystems { [string]: Logger }
local M = {
    Level = Level,
    level_name = level_name,
    file = nil,
    _file = nil,
    _subsystems = {},
}

---Create a new logger for the given subsystem with print and file log Level
---@param subsystem string the subsystem name
---@param level? number|LogLevel the print log level
---@param file_level? number|LogLevel the file log level
---@return Logger
function M:new(subsystem, level, file_level)
    local o = {
        subsystem = subsystem or 'undefined',
        level = level or Level.WARNING,
        file_level = file_level or Level.INFO,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Get the logger object for the give subsystem name
---@param subsystem string name of the subsystem
---@return Logger
function M.get_logger(subsystem)
    local exists = M._subsystems[subsystem]
    if exists == nil then
        exists = M:new(subsystem)
        M._subsystems[subsystem] = exists
    end
    return exists
end

---Open a log file
---@param path string log file path
function M.open_file(path)
    -- Close any open file
    if M._file ~= nil then
        M._file:close()
        M._file = nil
    end

    -- Open the file in append mode
    local file, err = io.open(path, 'a')
    if file then
        M._file = file
    else
        print('Error opening log file: ' .. err)
    end
end

---Write a log message with level
---@param level number|LogLevel message level
---@param ... any message
function M:log(level, ...)
    assert(level ~= nil, 'level cannot be nil')
    local args = { ... }

    local msg = nil
    local function get_msg()
        if msg then return msg end
        msg = ''
        for i = 1, #args do
            if i == 1 then
                msg = tostring(args[1])
            else
                msg = msg .. ' ' .. tostring(args[i])
            end
        end
        return msg
    end

    if (self.level ~= nil or M.level ~= nil) and level >= (self.level or M.level) then
        local short_msg = '[' .. self.subsystem .. '] ' .. get_msg()
        print(short_msg)
    end

    if M.file and (self.file_level ~= nil or M.file_level ~= nil) and level >= (self.file_level or self.level or M.file_level or M.level) then
        if M._file == nil then
            M.open_file(M.file)
        end

        if M._file then
            local long_msg = '['
                .. timestamp()
                .. '] ['
                .. self.subsystem
                .. '] ['
                .. level_name(level)
                .. '] '
                .. get_msg()
            M._file:write(long_msg .. '\n')
            M._file:flush()
        end
    end
end

---Write a log message with TRACE level
---@param ... any message
function M:trace(...)
    self:log(Level.TRACE, ...)
end

---Write a log message with DEBUG level
---@param ... any message
function M:debug(...)
    self:log(Level.DEBUG, ...)
end

---Write a log message with INFO level
---@param ... any message
function M:info(...)
    self:log(Level.INFO, ...)
end

---Write a log message with WARNING level
---@param ... any message
function M:warn(...)
    self:log(Level.WARNING, ...)
end

---Write a log message with ERROR level
---@param ... any message
function M:error(...)
    self:log(Level.ERROR, ...)
end

---Write a log message with ERROR level and call error()
---@param ... any message
function M:fatal(...)
    self:log(Level.fatal, ...)
    error(table.concat({ ... }, ''))
end

return M
