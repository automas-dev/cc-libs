package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'

logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/demo_logging.log',
    machine_level = logging.Level.TRACE,
    machine_filepath = 'logs/demo_logging.json',
}

local log = logging.get_logger('main')

log:trace('Trace Level Message')
log:debug('Debug Level Message')
log:info('Info Level Message')
log:warning('Warning Level Message')
log:error('Error Level Message')

local log2 = logging.get_logger('second')
log2:set_level(logging.Level.WARNING)

log2:trace('Trace Level Message')
log2:debug('Debug Level Message')
log2:info('Info Level Message')
log2:warning('Warning Level Message')
log2:error('Error Level Message')

local log3 = logging.Logger:new('to_remote', 0, logging.get_logger('root'))
log3:new_handler(logging.JsonFormatter:new(), logging.RemoteStream:new(0))

log3:trace('Trace Level Message')
log3:debug('Debug Level Message')
log3:info('Info Level Message')
log3:warning('Warning Level Message')
log3:error('Error Level Message')

local function foo()
    print('foo')
    error('here')
end

local success = log:catch_errors(foo)
assert(not success)

success = pcall(log.wrap_call, log, foo)
assert(not success)

local bar = log:wrap_fn(function()
    print('bar')
    error('there')
end)
success = pcall(bar)
assert(not success)

-- uncaught, because error is level 0, shell prints it in red instead of normal error format
bar()
