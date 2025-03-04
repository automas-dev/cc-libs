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

function test.first()
    local l = logging:new("subsystem")
    l.log = MagicMock()
    l:warning("hi")
    assert_eq(1, l.log.call_count)
    assert_eq(logging.Level.WARNING, l.log.args[2])
    assert_eq("hi", l.log.args[3])
end

return test
