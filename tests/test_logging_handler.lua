local handler = require 'cc-libs.util.logging.handler'
local Handler = handler.Handler

local test = {}

function test.new()
    local f = MagicMock()
    local s = MagicMock()
    local h = Handler:new(f, s)
    expect_eq(0, h.level)
    expect_eq(f, h.formatter)
    expect_eq(s, h.stream)
end

function test.new_level()
    local f = MagicMock()
    local s = MagicMock()
    local h = Handler:new(f, s, 1)
    expect_eq(1, h.level)
    expect_eq(f, h.formatter)
    expect_eq(s, h.stream)
end

function test.send()
    local f = MagicMock()
    f.format_record.return_value = 'msg'
    local s = MagicMock()
    s.send.return_value = true
    local h = Handler:new(f, s)
    local r = MagicMock()
    expect_true(h:send(r))
    assert_eq(1, f.format_record.call_count)
    expect_eq(r, f.format_record.args[2])
    assert_eq(1, s.send.call_count)
    expect_eq('msg', s.send.args[2])
end

function test.send_fail()
    local f = MagicMock()
    f.format_record.return_value = 'msg'
    local s = MagicMock()
    s.send.return_value = false
    local h = Handler:new(f, s)
    local r = MagicMock()
    expect_false(h:send(r))
    assert_eq(1, f.format_record.call_count)
    expect_eq(r, f.format_record.args[2])
    assert_eq(1, s.send.call_count)
    expect_eq('msg', s.send.args[2])
end

return test
