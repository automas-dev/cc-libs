---@diagnostic disable: inject-field, undefined-field
local logging = require 'cc-libs.util.logging'

local test = {}

function test.get_logger()
    local l = logging.get_logger('one')
    expect_eq('one', l.subsystem)
    expect_eq(0, l.level)
    l:set_level(1)
    l = logging.get_logger('one')
    expect_eq(1, l.level)
end

function test.basic_config()
    logging.basic_config {
        level = 1,
        file_level = 2,
        machine_level = 3,
        filepath = 'a.log',
        machine_filepath = 'b.log',
        force = true,
    }

    local root = logging.get_logger('root')
    expect_eq(3, #root.handlers)
    expect_eq(1, root.handlers[1].stream.level)
    expect_eq(2, root.handlers[2].stream.level)
    expect_eq(3, root.handlers[3].stream.level)
end

return test
