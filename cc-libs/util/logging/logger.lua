local log_record = require 'cc-libs.util.logging.record'
local Record = log_record.Record

local log_level = require 'cc-libs.util.logging.level'
local Level = log_level.Level

local log_handler = require 'cc-libs.util.logging.handler'
local Handler = log_handler.Handler

local pretty = require 'cc-libs.util.pretty'

---Get a string with filename and line of the calling code
---@return string traceback filename and line number
---@return debuginfo info name and debug
local function traceback()
    local info = debug.getinfo(3, 'Slfn')
    for _, check in ipairs({ 'traceback', 'trace', 'debug', 'info', 'warn', 'warning', 'error', 'fatal' }) do
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

local function table_to_string(...)
    local args = { ... }
    for i = 1, #args do
        args[i] = pretty.format(args[i])
    end
    return table.concat(args, ' ')
end

---Write a log message to each handler
---@param level number|LogLevel message level
function Logger:log(level, ...)
    if level < self.level then
        return
    end
    ---@diagnostic disable-next-line: undefined-field
    local log_time = os.epoch('local') / 1000 -- luacheck: ignore
    local msg = table_to_string(...)
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

-- TODO test traceback
---Write a log message with TRACE level including a traceback
---@param ... any message
function Logger:traceback(...)
    self:log(Level.TRACE, ...)
    self:log(Level.TRACE, debug.traceback('', 2))
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
---@deprecated
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
    error(table_to_string(...))
end

---Call a function and log any errors that occur. The error is caught and not raised again.
---@generic T
---@generic R
---@param fn fun(T): R function to run catching and logging errors
---@param ... T to the function
---@return R ... result of `fn`
function Logger:catch_errors(fn, ...)
    local res = table.pack(xpcall(fn, debug.traceback, ...))
    local success = res[1]

    if not success then
        self:error(res[2])
    end

    return table.unpack(res)
end

---Call a function and log any errors that occur. The error is then raised again.
---@generic T
---@generic R
---@param fn fun(T): R function to run catching and logging errors
---@param ... T to the function
---@return R ... result of `fn`
function Logger:wrap_call(fn, ...)
    local res = table.pack(xpcall(fn, debug.traceback, ...))
    local success = res[1]

    if not success then
        local err = res[2]
        self:error(err)
        error(err, 0) -- 0 to re-raise error since we already include the stack trace
    end

    -- Unpack at 2 to exclude the success bool from xpcall
    return table.unpack(res, 2)
end

---Return a wrapped function that logs any errors that occur before raising it again.
---@generic T : function
---@param fn T function to run catching, logging and re-raising errors
---@return T wrapped_fn function wrapping `fn`
function Logger:wrap_fn(fn)
    return function(...)
        return self:wrap_call(fn, ...)
    end
end

return {
    Logger = Logger,
}
