local formatter = require 'cc-libs.util.logging.formatter'
local Record = formatter.Record
local Formatter = formatter.Formatter
local ShortFormatter = formatter.ShortFormatter
local LongFormatter = formatter.LongFormatter

local test = {}

function test.record()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('ss', r.subsystem)
    expect_eq(1, r.level)
    expect_eq('lc', r.location)
    expect_eq('msg', r.message)
    expect_eq(1234, r.time)
end

function test.formatter()
    local f = Formatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('msg', f:format_record(r))
end

function test.short_formatter()
    local f = ShortFormatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('[ss] msg', f:format_record(r))
end

function test.long_formatter()
    local f = LongFormatter:new()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('[1969-12-31T19:20:34] [ss] [lc] [debug] msg', f:format_record(r))
end

return test
