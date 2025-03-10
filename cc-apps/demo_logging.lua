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
