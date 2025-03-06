local json = require 'cc-libs.util.json'

---@enum LogLevel
local Level = {
    TRACE = 0,
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    FATAL = 5,
}

---Get the string name of a level
---@param level number|LogLevel level or level number
---@return string
local function level_name(level)
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
local function level_from_name(name)
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

---Get a string timestamp for the current time
---@return string
local function timestamp()
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%Y-%m-%dT%H:%M:%S')
end

---Get a string with filename and line of the calling code
---@return string traceback, table info name and debug info
local function traceback()
    local info = debug.getinfo(3, 'Slfn')
    for _, check in ipairs({ 'trace', 'debug', 'info', 'warn', 'warning', 'error', 'fatal' }) do
        if info.name == check then
            info = debug.getinfo(4, 'Slf')
            break
        end
    end
    local traceback_str = info.source .. ':' .. info.currentline
    return traceback_str, info
end

---@class Logger
---@field subsystem string name of the subsystem
---@field level number|LogLevel minimum log level for terminal logging
---@field file_level number|LogLevel minimum log level for file logging
---@field machine_log boolean write log file in a machine readable format (json)
---@field file? string active log file path if _file is not nil
---@field _file? file*
---@field _subsystems { [string]: Logger }
local M = {
    Level = Level,
    level_name = level_name,
    level_from_name = level_from_name,
    file = nil,
    _file = nil,
    _subsystems = {},
}

---Create a new logger for the given subsystem with print and file log Level
---@param subsystem string the subsystem name
---@param level? number|LogLevel the print log level
---@param file_level? number|LogLevel the file log level
---@param machine_log? boolean change log file to machine readable format
---@return Logger
function M:new(subsystem, level, file_level, machine_log)
    assert(subsystem ~= nil, 'subsystem must not be nil')
    local o = {
        subsystem = subsystem,
        level = level or Level.INFO,
        file_level = file_level,
        machine_log = machine_log or false,
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
function M:open_file(path)
    -- Close any open file
    if self._file ~= nil then
        self._file:close()
        self._file = nil
    end

    -- Open the file in append mode
    local file, err = io.open(path, 'a')
    if file then
        self._file = file
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

    if self.file and (self.file_level ~= nil or M.file_level ~= nil) and level >= (self.file_level or self.level or M.file_level or M.level) then
        if self._file == nil then
            self:open_file(self.file)
        end

        if self._file then
            local long_msg
            if self.machine_log or self.machine_log then
                long_msg = json.encode({
                    timestamp = timestamp(),
                    subsystem = self.subsystem,
                    location = traceback(),
                    level = level_name(level),
                    msg = get_msg(),
                })
            else
                long_msg = '['
                    .. timestamp()
                    .. '] ['
                    .. self.subsystem
                    .. '] ['
                    .. traceback()
                    .. '] ['
                    .. level_name(level)
                    .. '] '
                    .. get_msg()
            end
            self._file:write(long_msg .. '\n')
            self._file:flush()
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

---Write a log message with WARNING level
---@param ... any message
function M:warning(...)
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
    self:log(Level.FATAL, ...)
    error(table.concat({ ... }, ''))
end

return M
