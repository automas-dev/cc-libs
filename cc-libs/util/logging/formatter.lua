local json = require 'cc-libs.util.json'

local _level = require 'cc-libs.util.logging.level'

---Get a string timestamp for the current time
---@param time? number
---@return string
---@diagnostic disable-next-line: unused-function
local function time_only(time)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%H:%M:%S', time)
end

---Get a string timestamp for the current date and time
---@param time? number
---@return string
---@diagnostic disable-next-line: unused-function
local function datetime(time)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%Y-%m-%dT%H:%M:%S', time)
end

---@class Formatter
---@field format_record fun(self: Formatter, record: Record): string

---@class ShortFormatter : Formatter
---@field show_id boolean show the computer id in the message
local ShortFormatter = {}

---Create a new ShortFormatter instance
---@param show_id? boolean show the computer id in the message
---@return ShortFormatter
function ShortFormatter:new(show_id)
    local o = {
        show_id = show_id or false,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Format record into a string
---@param record Record the record to format
---@return string text the formatted message for record
function ShortFormatter:format_record(record)
    local prefix = ''
    if self.show_id then
        prefix = '[' .. tostring(record.host_id) .. ':' .. tostring(record.host_name) .. '] '
    end
    return prefix .. '[' .. record.subsystem .. '] ' .. record.message
end

---@class LongFormatter : Formatter
local LongFormatter = {}

---Create a new ShortFormatter instance
---@return LongFormatter
function LongFormatter:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Format record into a string
---@param record Record the record to format
---@return string text the formatted message for record
function LongFormatter:format_record(record)
    return '['
        .. datetime(record.time)
        .. '] ['
        .. record.subsystem
        .. '] ['
        .. record.location
        .. '] ['
        .. _level.level_name(record.level)
        .. '] '
        .. record.message
end

---@class JsonFormatter : Formatter
local JsonFormatter = {}

---Create a new ShortFormatter instance
---@return JsonFormatter
function JsonFormatter:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Format record into a string
---@param record Record the record to format
---@return string text the formatted message for record
function JsonFormatter:format_record(record)
    return json.encode({
        timestamp = datetime(record.time),
        subsystem = record.subsystem,
        location = record.location,
        level = _level.level_name(record.level),
        message = record.message,
        host = record.host_id .. ':' .. record.host_name,
        gps = record.gps,
    })
end

return {
    ShortFormatter = ShortFormatter,
    LongFormatter = LongFormatter,
    JsonFormatter = JsonFormatter,
}
