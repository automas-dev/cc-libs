---@class Handler
---@field formatter Formatter
---@field stream Stream
---@field level number|LogLevel
local Handler = {}

---Create a new Handler instance
---@param formatter Formatter
---@param stream Stream
---@param level? number|LogLevel minimum log level for this handler
---@return Handler
function Handler:new(formatter, stream, level)
    local o = {
        formatter = formatter,
        stream = stream,
        level = level or 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Format and send a record
---@param record Record the message record
---@return boolean success was the message send successful
function Handler:send(record)
    local message = self.formatter:format_record(record)
    return self.stream:send(message)
end

return {
    Handler = Handler,
}
