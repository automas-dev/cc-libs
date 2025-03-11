---@diagnostic disable: inject-field, undefined-field
-- luacheck: ignore 143 142

local stream = require 'cc-libs.util.logging.stream'
local ConsoleStream = stream.ConsoleStream
local FileStream = stream.FileStream
local RemoteStream = stream.RemoteStream

local test = {}

function test.setup()
    patch('io')
    patch('print')
    patch('rednet')
    patch('peripheral')
end

function test.console_new_empty()
    local s = ConsoleStream:new()
    expect_eq(0, s.level)
end

function test.console_new_level()
    local s = ConsoleStream:new(2)
    expect_eq(2, s.level)
end

function test.console_send()
    local s = ConsoleStream:new()
    local res = s:send('hi')
    expect_true(res)
    assert_eq(1, print.call_count)
    expect_eq(1, #print.args)
    expect_eq('hi', print.args[1])
end

function test.file_new_empty()
    local s = pcall(FileStream.new)
    expect_false(s)
end

function test.file_new_default_level()
    local s = FileStream:new('a.log')
    expect_eq('a.log', s.filename)
    expect_eq(nil, s.file)
    expect_eq(0, s.level)
end

function test.file_new_level()
    local s = FileStream:new('a.log', 2)
    expect_eq('a.log', s.filename)
    expect_eq(nil, s.file)
    expect_eq(2, s.level)
end

function test.file_open_file()
    local s = FileStream:new('a.log')
    io.open.return_unpack = { 'a', nil }
    local success, err = s:open_file('b.log')
    expect_true(success)
    expect_eq(nil, err)
    expect_eq('a', s.file)
end

function test.file_open_file_close_first()
    local s = FileStream:new('a.log')
    io.open.return_unpack = { 'a', nil }
    local mock_file = MagicMock()
    s.file = mock_file
    local success, err = s:open_file('b.log')
    expect_true(success)
    expect_eq(nil, err)
    expect_eq(1, mock_file.close.call_count)
    expect_eq('a', s.file)
end

function test.file_open_file_fail()
    local s = FileStream:new('a.log')
    io.open.return_unpack = { false, 'error message' }
    local success, err = s:open_file('b.log')
    expect_false(success)
    expect_eq('error message', err)
    assert_eq(1, print.call_count)
    assert_eq('Error opening log file: error message', print.args[1])
end

function test.file_send()
    local s = FileStream:new('a.log')
    s.file = MagicMock()
    local res = s:send('hi')
    expect_true(res)
    assert_eq(2, s.file.write.call_count)
    expect_eq('hi', s.file.write.calls[1][2])
    expect_eq('\n', s.file.write.calls[2][2])
    expect_eq(1, s.file.flush.call_count)
end

function test.file_send_open_file()
    local s = FileStream:new('a.log')
    s.open_file = MagicMock()
    local res = s:send('hi')
    expect_false(res)
    assert_eq(1, s.open_file.call_count)
    expect_eq('a.log', s.open_file.args[2])
end

function test.remote_new_empty()
    local s = RemoteStream:new()
    expect_eq(0, s.level)
    expect_eq(1, peripheral.find.call_count)
    expect_eq('modem', peripheral.find.args[1])
    expect_eq(rednet.open, peripheral.find.args[2])
end

function test.remote_new_level()
    local s = RemoteStream:new(2)
    expect_eq(2, s.level)
end

function test.remote_send()
    local s = RemoteStream:new()
    local res = s:send('hi')
    expect_true(res)
    assert_eq(1, rednet.broadcast.call_count)
    expect_eq(2, #rednet.broadcast.args)
    expect_eq('hi', rednet.broadcast.args[1])
    expect_eq('remote_log', rednet.broadcast.args[2])
end

return test
