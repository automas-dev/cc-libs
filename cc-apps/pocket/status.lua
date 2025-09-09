package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_status.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local function run()
    peripheral.find('modem', rednet.open)

    local x, y, z = gps.locate()

    log:info('Send telemetry')
    rednet.broadcast(json.encode({ position = { x = x, y = y, z = z } }), 'telemetry')

    log:info('Request report')
    rednet.broadcast(json.encode({ id = 3 }), 'report')

    local id, message = rednet.receive('mainframe_response')
    log:info('Response', message)
end

log:catch_errors(run)
