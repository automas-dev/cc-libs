---@diagnostic disable: undefined-field
-- luacheck: ignore 143 142

local json = require 'cc-libs.util.json'

local record = require 'cc-libs.util.logging.record'
local Record = record.Record

local formatter = require 'cc-libs.util.logging.formatter'
local ShortFormatter = formatter.ShortFormatter
local LongFormatter = formatter.LongFormatter
local JsonFormatter = formatter.JsonFormatter

local test = {}

function test.setup()
    patch('os.getComputerID').return_value = 7
    patch('os.getComputerLabel').return_value = 'name'
    patch('_G.gps').locate.return_unpack = { 1, 2, 3 }
end

function test.short_formatter()
    local f = ShortFormatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('[ss] msg', f:format_record(r))
end

function test.short_formatter_prefix()
    local f = ShortFormatter:new(true)
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('[7:name] [ss] msg', f:format_record(r))
end

function test.long_formatter()
    local f = LongFormatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1741354307)
    local local_date = os.date('%Y-%m-%dT%H:%M:%S', 1741354307)
    expect_eq('[' .. local_date .. '] [ss] [lc] [debug] msg', f:format_record(r))
end

function test.json_formatter()
    local f = JsonFormatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1741354307)
    local local_date = os.date('%Y-%m-%dT%H:%M:%S', 1741354307)
    local text = f:format_record(r)
    local decoded = json.decode(text)
    expect_eq(local_date, decoded.timestamp)
    expect_eq('ss', decoded.subsystem)
    expect_eq('lc', decoded.location)
    expect_eq('debug', decoded.level)
    expect_eq('msg', decoded.message)
    expect_eq('7:name', decoded.host)
    expect_eq('7:name', decoded.host)
    expect_eq(1, decoded.gps.x)
    expect_eq(2, decoded.gps.y)
    expect_eq(3, decoded.gps.z)
end

return test
