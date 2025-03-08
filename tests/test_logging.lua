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

function test.basic_config() end

return test
