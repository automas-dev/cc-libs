local json = require 'cc-libs.util.json'

local _level = require 'cc-libs.util.logging.level'

---Get a string timestamp for the current time
---@param time? number
---@return string
local function time_only(time)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%H:%M:%S', time)
end

---Get a string timestamp for the current date and time
---@param time? number
---@return string
local function datetime(time)
    ---@diagnostic disable-next-line: return-type-mismatch
    return os.date('%Y-%m-%dT%H:%M:%S', time)
end

---@class Record
---@field subsystem string
---@field level number|LogLevel
---@field location string
---@field message string
---@field time number
local Record = {}

---Create a new Record instance
---@param subsystem string
---@param level number|LogLevel
---@param location string
---@param message string
---@return Record
function Record:new(subsystem, level, location, message, time)
    local o = {
        subsystem = subsystem,
        level = level,
        location = location,
        message = message,
        time = time,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@class Formatter
local Formatter = {}

---Create a new Formatter instance
---@return Formatter
function Formatter:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Format record into a string
---@param record Record the record to format
---@return string text the formatted message for record
function Formatter:format_record(record)
    return record.message
end

---@class ShortFormatter : Formatter
local ShortFormatter = Formatter:new()

function ShortFormatter:format_record(record)
    return '[' .. record.subsystem .. '] ' .. record.message
end

---@class LongFormatter : Formatter
local LongFormatter = Formatter:new()

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
local JsonFormatter = Formatter:new()

function JsonFormatter:format_record(record)
    return json.encode({
        timestamp = datetime(record.time),
        subsystem = record.subsystem,
        location = record.location,
        level = record.level,
        message = record.message,
    })
end

return {
    Formatter = Formatter,
    Record = Record,
    ShortFormatter = ShortFormatter,
    LongFormatter = LongFormatter,
    JsonFormatter = JsonFormatter,
}
