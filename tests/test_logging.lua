local logging = require 'cc-libs.util.logging'

local test = {}

local _old_os
local _old_io

function test.setup()
    _old_os = os
    os = MagicMock()
    _old_io = io
    io = MagicMock()
end

function test.teardown()
    os = _old_os
    io = _old_io
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

function test.first()
    local l = logging:new('subsystem')
    l.log = MagicMock()
    l:warning('hi')
    assert_eq(1, l.log.call_count)
    expect_eq(logging.Level.WARNING, l.log.args[2])
    expect_eq('hi', l.log.args[3])
end

return test
