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
---@field host_id number
---@field host_name string
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
        -- luacheck: push ignore 143
        host_id = os.getComputerID(),
        host_name = os.getComputerLabel() or '',
        --luacheck: pop
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@class Formatter
local Formatter = {}

---Format record into a string
---@param record Record the record to format
---@return string text the formatted message for record
function Formatter:format_record(record)
    return record.message
end

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

function JsonFormatter:format_record(record)
    return json.encode({
        timestamp = datetime(record.time),
        subsystem = record.subsystem,
        location = record.location,
        level = _level.level_name(record.level),
        message = record.message,
        host = record.host_id .. ':' .. record.host_name,
    })
end

return {
    Record = Record,
    ShortFormatter = ShortFormatter,
    LongFormatter = LongFormatter,
    JsonFormatter = JsonFormatter,
}
