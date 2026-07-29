package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_wait_for_dead.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry
local PayloadType = ccl_telemetry.PayloadType

local telem = get_telemetry()
local runner = telem:make_runner()

runner:listen_for_event('runner.thread_died', function(message)
    assert(message.type == PayloadType.EVENT)
    local host = message.host_id .. ':' .. message.host_name
    print('[' .. host .. ']', message.event.message, json.encode(message.event.data))
end)

runner:run()
