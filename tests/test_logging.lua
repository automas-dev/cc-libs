---@diagnostic disable: inject-field, undefined-field

local logging = require 'cc-libs.util.logging'

local test = {}

local _old_os
local _old_io
local _old_print

function test.setup()
    _old_os = os
    os = MagicMock()
    _old_io = io
    io = MagicMock()
    _old_print = print
    print = MagicMock()
    logging.file = nil
    logging._file = nil
    logging._subsystems = {}
end

function test.teardown()
    os = _old_os
    io = _old_io
    print = _old_print
end

function test.level_name()
    expect_eq('trace', logging.level_name(logging.Level.TRACE))
    expect_eq('debug', logging.level_name(logging.Level.DEBUG))
    expect_eq('info', logging.level_name(logging.Level.INFO))
    expect_eq('warning', logging.level_name(logging.Level.WARNING))
    expect_eq('error', logging.level_name(logging.Level.ERROR))
    expect_eq('fatal', logging.level_name(logging.Level.FATAL))
end

function test.level_from_name()
    expect_eq(logging.Level.TRACE, logging.level_from_name('trace'))
    expect_eq(logging.Level.TRACE, logging.level_from_name('TRACE'))
    expect_eq(logging.Level.TRACE, logging.level_from_name('Trace'))
    expect_eq(logging.Level.DEBUG, logging.level_from_name('debug'))
    expect_eq(logging.Level.DEBUG, logging.level_from_name('DEBUG'))
    expect_eq(logging.Level.DEBUG, logging.level_from_name('Debug'))
    expect_eq(logging.Level.INFO, logging.level_from_name('info'))
    expect_eq(logging.Level.INFO, logging.level_from_name('INFO'))
    expect_eq(logging.Level.INFO, logging.level_from_name('Info'))
    expect_eq(logging.Level.WARNING, logging.level_from_name('warning'))
    expect_eq(logging.Level.WARNING, logging.level_from_name('WARNING'))
    expect_eq(logging.Level.WARNING, logging.level_from_name('Warning'))
    expect_eq(logging.Level.ERROR, logging.level_from_name('error'))
    expect_eq(logging.Level.ERROR, logging.level_from_name('ERROR'))
    expect_eq(logging.Level.ERROR, logging.level_from_name('Error'))
    expect_eq(logging.Level.FATAL, logging.level_from_name('fatal'))
    expect_eq(logging.Level.FATAL, logging.level_from_name('FATAL'))
    expect_eq(logging.Level.FATAL, logging.level_from_name('Fatal'))
end

function test.level_order()
    expect_lt(logging.Level.TRACE, logging.Level.DEBUG)
    expect_lt(logging.Level.DEBUG, logging.Level.INFO)
    expect_lt(logging.Level.INFO, logging.Level.WARNING)
    expect_lt(logging.Level.WARNING, logging.Level.ERROR)
    expect_lt(logging.Level.ERROR, logging.Level.FATAL)
end

function test.new_no_args()
    local success = pcall(logging.new)
    expect_false(success)
end

function test.new_name_only()
    local log = logging:new('test')
    expect_eq('test', log.subsystem)
    expect_eq(logging.Level.INFO, log.level)
    expect_eq(nil, log.file_level)
    expect_eq(nil, log.file)
    expect_eq(nil, log._file)
    expect_false(log.machine_log)
end

function test.new_level()
    local log = logging:new('test', logging.Level.ERROR)
    expect_eq('test', log.subsystem)
    expect_eq(logging.Level.ERROR, log.level)
    expect_eq(nil, log.file_level)
    expect_eq(nil, log.file)
    expect_eq(nil, log._file)
    expect_false(log.machine_log)
end

function test.new_file_level()
    local log = logging:new('test', logging.Level.ERROR, logging.Level.TRACE)
    expect_eq('test', log.subsystem)
    expect_eq(logging.Level.ERROR, log.level)
    expect_eq(logging.Level.TRACE, log.file_level)
    expect_eq(nil, log.file)
    expect_eq(nil, log._file)
    expect_false(log.machine_log)
end

function test.new_machine_log()
    local log = logging:new('test', logging.Level.ERROR, logging.Level.TRACE, true)
    expect_eq('test', log.subsystem)
    expect_eq(logging.Level.ERROR, log.level)
    expect_eq(logging.Level.TRACE, log.file_level)
    expect_eq(nil, log.file)
    expect_eq(nil, log._file)
    expect_true(log.machine_log)
end

function test.get_logger()
    local log = logging.get_logger('one')
    expect_eq('one', log.subsystem)
    expect_eq(logging.Level.INFO, log.level)
    expect_eq(nil, log.file_level)
    expect_eq(nil, log.file)
    expect_eq(nil, log._file)
    expect_false(log.machine_log)

    local log2 = logging.get_logger('one')
    expect_eq(log, log2)
end

function test.open_file()
    local log = logging:new('test')
    io.open.return_unpack = { 'o', nil }
    local success, err = pcall(log.open_file, log, 'file.log')
    assert_true(success, err)
    expect_eq(0, print.call_count)
    expect_eq('o', log._file)
    assert_eq(1, io.open.call_count)
    expect_eq('file.log', io.open.args[1])
end

function test.open_file_fail()
    local log = logging:new('test')
    io.open.return_unpack = { nil, 'error message' }
    local success, err = pcall(log.open_file, log, 'file.log')
    assert_true(success, err)
    assert_eq(1, print.call_count)
    expect_eq('Error opening log file: error message', print.args[1])
    expect_eq(nil, log._file)
    assert_eq(1, io.open.call_count)
    expect_eq('file.log', io.open.args[1])
end

function test.open_file_close_first()
    local log = logging:new('test')
    local mock_file = MagicMock()
    log._file = mock_file
    io.open.return_unpack = { 'o', nil }
    local success, err = pcall(log.open_file, log, 'file.log')
    assert_true(success, err)
    assert_eq(0, print.call_count)
    expect_eq(1, mock_file.close.call_count)
    expect_eq('o', log._file)
    assert_eq(1, io.open.call_count)
    expect_eq('file.log', io.open.args[1])
end

function test.level_methods()
    local l = logging:new('subsystem')
    l.log = MagicMock()
    l:trace('a')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.TRACE, l.log.args[2])
    expect_eq('a', l.log.args[3])
    l.log.reset()
    l:debug('b')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.DEBUG, l.log.args[2])
    expect_eq('b', l.log.args[3])
    l.log.reset()
    l:info('c')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.INFO, l.log.args[2])
    expect_eq('c', l.log.args[3])
    l.log.reset()
    l:warn('d')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.WARNING, l.log.args[2])
    expect_eq('d', l.log.args[3])
    l.log.reset()
    l:warning('e')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.WARNING, l.log.args[2])
    expect_eq('e', l.log.args[3])
    l.log.reset()
    l:error('f')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.ERROR, l.log.args[2])
    expect_eq('f', l.log.args[3])
    l.log.reset()

    local success, err = pcall(l.fatal, l, 'g')
    assert_false(success)
    assert_true(type(err) == 'string', 'Error was not a string, cannot check')
    ---@diagnostic disable-next-line: need-check-nil
    expect_true(err:find(': g$'))
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.FATAL, l.log.args[2])
    expect_eq('g', l.log.args[3])
end

return test
