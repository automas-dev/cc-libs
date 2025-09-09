package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    remote_enabled = true,
}
local log = logging.get_logger('main')

log:info('Hello from me')
log:warning('You should see this in console')
log:debug('Save me')
log:trace('Ignore me')
