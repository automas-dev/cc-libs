---@diagnostic disable: inject-field, undefined-field

local logger = require 'cc-libs.util.logging.logger'
local Logger = logger.Logger

local log_level = require 'cc-libs.util.logging.level'
local Level = log_level.Level

local log_formatter = require 'cc-libs.util.logging.formatter'
local Record = log_formatter.Record

local test = {}

local _old_os

function test.setup()
    _old_os = os
    os = MagicMock()
end

function test.teardown()
    os = _old_os
end

function test.new()
    local l = Logger:new('ss')
    expect_eq('ss', l.subsystem)
    expect_eq(0, l.level)
    expect_eq(0, #l.handlers)
end

function test.new_level()
    local l = Logger:new('ss', 1)
    expect_eq('ss', l.subsystem)
    expect_eq(1, l.level)
    expect_eq(0, #l.handlers)
end

function test.new_parent()
    local parent = MagicMock()
    local l = Logger:new('ss', 1, parent)
    expect_eq('ss', l.subsystem)
    expect_eq(1, l.level)
    expect_eq(0, #l.handlers)
    expect_eq(parent, l.parent)
end

function test.new_no_subsystem()
    expect_false(pcall(Logger.new))
end

function test.add_handler()
    local l = Logger:new('ss')
    local h = MagicMock()
    l:add_handler(h)
    assert_eq(1, #l.handlers)
    expect_eq(h, l.handlers[1])
end

function test.new_handler()
    local f = MagicMock()
    local s = MagicMock()
    local l = Logger:new('ss')
    l:new_handler(f, s)
    assert_eq(1, #l.handlers)
    assert_eq(f, l.handlers[1].formatter)
    assert_eq(s, l.handlers[1].stream)
    assert_eq(0, l.handlers[1].level)
end

function test.new_handler_level()
    local f = MagicMock()
    local s = MagicMock()
    local l = Logger:new('ss')
    l:new_handler(f, s, 1)
    assert_eq(1, #l.handlers)
    assert_eq(f, l.handlers[1].formatter)
    assert_eq(s, l.handlers[1].stream)
    assert_eq(1, l.handlers[1].level)
end

function test.set_level()
    local l = Logger:new('ss')
    expect_eq(0, l.level)
    l:set_level(1)
    expect_eq(1, l.level)
end

function test.log()
    local l = Logger:new('ss')
    local h = MagicMock()
    h.level = 0
    h.stream.level = 0
    l.handlers[1] = h
    local mock_record = MagicMock()
    Record.new = MagicMock {
        return_value = mock_record,
    }
    os.time.return_value = 12
    l:log(1, 'a')
    expect_eq(1, os.time.call_count)
    assert_eq(1, Record.new.call_count)
    expect_eq('ss', Record.new.args[2])
    expect_eq(1, Record.new.args[3])
    expect_lt(1, #Record.new.args[4])
    expect_eq('a', Record.new.args[5])
    expect_eq(12, Record.new.args[6])
    assert_eq(1, h.send.call_count)
    expect_eq(mock_record, h.send.args[2])
end

function test.log_parent_handlers()
    local parent = MagicMock()
    local h = MagicMock()
    h.level = 0
    h.stream.level = 0
    parent.handlers = {
        h,
    }
    local l = Logger:new('ss', 0, parent)
    l:log(0, 'hi')
    expect_eq(1, h.send.call_count)
end

function test.log_logger_block()
    local l = Logger:new('ss', 1)
    local h = MagicMock()
    l.handlers[1] = h
    Record.new = MagicMock()
    os.time.return_value = 12
    l:log(0, 'a')
    expect_eq(0, l.handlers[1].call_count)
end

function test.log_handler_block()
    local l = Logger:new('ss')
    local h = MagicMock()
    h.level = 1
    h.stream.level = 0
    l.handlers[1] = h
    Record.new = MagicMock()
    os.time.return_value = 12
    l:log(0, 'a')
    expect_eq(0, l.handlers[1].call_count)
end

function test.log_stream_block()
    local l = Logger:new('ss')
    local h = MagicMock()
    h.level = 0
    h.stream.level = 1
    l.handlers[1] = h
    Record.new = MagicMock()
    os.time.return_value = 12
    l:log(0, 'a')
    expect_eq(0, l.handlers[1].call_count)
end

function test.log_handler_stream_block()
    local l = Logger:new('ss')
    local h = MagicMock()
    h.level = 1
    h.stream.level = 1
    l.handlers[1] = h
    Record.new = MagicMock()
    os.time.return_value = 12
    l:log(0, 'a')
    expect_eq(0, l.handlers[1].call_count)
end

function test.level_methods()
    local l = Logger:new('ss')
    l.log = MagicMock()
    l:trace('a')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.TRACE, l.log.args[2])
    expect_eq('a', l.log.args[3])
    l.log.reset()
    l:debug('b')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.DEBUG, l.log.args[2])
    expect_eq('b', l.log.args[3])
    l.log.reset()
    l:info('c')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.INFO, l.log.args[2])
    expect_eq('c', l.log.args[3])
    l.log.reset()
    l:warn('d')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.WARNING, l.log.args[2])
    expect_eq('d', l.log.args[3])
    l.log.reset()
    l:warning('e')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.WARNING, l.log.args[2])
    expect_eq('e', l.log.args[3])
    l.log.reset()
    l:error('f')
    assert_eq(1, l.log.call_count)
    expect_eq(Level.ERROR, l.log.args[2])
    expect_eq('f', l.log.args[3])
    l.log.reset()

    local success, err = pcall(l.fatal, l, 'g')
    assert_false(success)
    assert_true(type(err) == 'string', 'Error was not a string, cannot check')
    ---@diagnostic disable-next-line: need-check-nil
    expect_true(err:find(': g$'))
    assert_eq(1, l.log.call_count)
    expect_eq(Level.FATAL, l.log.args[2])
    expect_eq('g', l.log.args[3])
end

return test
