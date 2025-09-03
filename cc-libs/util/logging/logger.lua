local log_formatter = require 'cc-libs.util.logging.formatter'
local Record = log_formatter.Record

local log_level = require 'cc-libs.util.logging.level'
local Level = log_level.Level

local log_handler = require 'cc-libs.util.logging.handler'
local Handler = log_handler.Handler

---Get a string with filename and line of the calling code
---@return string traceback filename and line number
---@return debuginfo info name and debug
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
---@field level number|LogLevel minimum log level for this logger
---@field handlers Handler[]
---@field parent? Logger
local Logger = {}

---Create a new Logger instance
---@param subsystem string name of the subsystem
---@param level? number|LogLevel minimum log level for this logger
---@param parent? Logger parent logger for default handlers
---@return Logger
function Logger:new(subsystem, level, parent)
    assert(subsystem ~= nil, 'subsystem must not be nil')
    local o = {
        subsystem = subsystem,
        level = level or 0,
        handlers = {},
        parent = parent,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a handler to this logger
---@param handler Handler
function Logger:add_handler(handler)
    table.insert(self.handlers, handler)
end

---Create and add a handler to this logger
---@param formatter Formatter
---@param stream Stream
---@param level? number|LogLevel minimum log level for this handler
function Logger:new_handler(formatter, stream, level)
    local handler = Handler:new(formatter, stream, level)
    self:add_handler(handler)
end

---Update the logger level
---@param level number|LogLevel
function Logger:set_level(level)
    self.level = level
end

---Write a log message to each handler
---@param level number|LogLevel message level
function Logger:log(level, ...)
    if level < self.level then
        return
    end
    local args = { ... }
    local log_time = os.epoch('local') / 1000 -- luacheck: ignore
    local msg = ''
    for i = 1, #args do
        if i == 1 then
            msg = tostring(args[1])
        else
            msg = msg .. ' ' .. tostring(args[i])
        end
    end
    local record = Record:new(self.subsystem, level, traceback(), msg, log_time)
    local handlers = self.handlers
    --- root should always have handlers after basic_config is called
    if #handlers == 0 and self.parent ~= nil then
        handlers = self.parent.handlers
    end
    for _, h in ipairs(handlers) do
        if level >= h.level and level >= h.stream.level then
            h:send(record)
        end
    end
end

---Write a log message with TRACE level
---@param ... any message
function Logger:trace(...)
    self:log(Level.TRACE, ...)
end

---Write a log message with DEBUG level
---@param ... any message
function Logger:debug(...)
    self:log(Level.DEBUG, ...)
end

---Write a log message with INFO level
---@param ... any message
function Logger:info(...)
    self:log(Level.INFO, ...)
end

---Write a log message with WARNING level
---@param ... any message
function Logger:warn(...)
    self:log(Level.WARNING, ...)
end

---Write a log message with WARNING level
---@param ... any message
function Logger:warning(...)
    self:log(Level.WARNING, ...)
end

---Write a log message with ERROR level
---@param ... any message
function Logger:error(...)
    self:log(Level.ERROR, ...)
end

---Write a log message with ERROR level and call error()
---@param ... any message
function Logger:fatal(...)
    self:log(Level.FATAL, ...)
    error(table.concat({ ... }, ''))
end

---Call a function and log any errors that occur
---@param fn fun() function to run catching and logging errors
---@return any result of `fn`
function Logger:log_errors(fn)
    local status, res = xpcall(fn, debug.traceback)

    if not status then
        self:error(res)
    end

    return res
end

return {
    Logger = Logger,
}
