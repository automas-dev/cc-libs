---@diagnostic disable: inject-field, undefined-field

local level = require 'cc-libs.util.logging.level'

local test = {}

function test.level_name()
    expect_eq('trace', level.level_name(level.Level.TRACE))
    expect_eq('debug', level.level_name(level.Level.DEBUG))
    expect_eq('info', level.level_name(level.Level.INFO))
    expect_eq('warning', level.level_name(level.Level.WARNING))
    expect_eq('error', level.level_name(level.Level.ERROR))
    expect_eq('fatal', level.level_name(level.Level.FATAL))
end

function test.level_from_name()
    expect_eq(level.Level.TRACE, level.level_from_name('trace'))
    expect_eq(level.Level.TRACE, level.level_from_name('TRACE'))
    expect_eq(level.Level.TRACE, level.level_from_name('Trace'))
    expect_eq(level.Level.DEBUG, level.level_from_name('debug'))
    expect_eq(level.Level.DEBUG, level.level_from_name('DEBUG'))
    expect_eq(level.Level.DEBUG, level.level_from_name('Debug'))
    expect_eq(level.Level.INFO, level.level_from_name('info'))
    expect_eq(level.Level.INFO, level.level_from_name('INFO'))
    expect_eq(level.Level.INFO, level.level_from_name('Info'))
    expect_eq(level.Level.WARNING, level.level_from_name('warning'))
    expect_eq(level.Level.WARNING, level.level_from_name('WARNING'))
    expect_eq(level.Level.WARNING, level.level_from_name('Warning'))
    expect_eq(level.Level.ERROR, level.level_from_name('error'))
    expect_eq(level.Level.ERROR, level.level_from_name('ERROR'))
    expect_eq(level.Level.ERROR, level.level_from_name('Error'))
    expect_eq(level.Level.FATAL, level.level_from_name('fatal'))
    expect_eq(level.Level.FATAL, level.level_from_name('FATAL'))
    expect_eq(level.Level.FATAL, level.level_from_name('Fatal'))
end

function test.level_order()
    expect_lt(level.Level.TRACE, level.Level.DEBUG)
    expect_lt(level.Level.DEBUG, level.Level.INFO)
    expect_lt(level.Level.INFO, level.Level.WARNING)
    expect_lt(level.Level.WARNING, level.Level.ERROR)
    expect_lt(level.Level.ERROR, level.Level.FATAL)
end

return test
