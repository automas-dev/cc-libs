package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/telemetry_watch.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('telemetry_monitor', 'Monitor and print telemetry events')
-- TODO update args and options
parser:add_option(nil, 'id', 'computer id filter', true)
parser:add_option(nil, 'host', 'computer label filter', true)
parser:add_option(
    't',
    'types',
    'Telemetry payload types as single upper case letter (eg. EA for events and alerts)',
    true
)
local args = parser:parse_args({ ... })

local id_filter = args.id
local host_filter = args.host
local type_filter = args.types or 'EAS'

log:info('Starting with args', args)

local json = require 'cc-libs.util.json'

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry
local PayloadType = ccl_telemetry.PayloadType

local telem = get_telemetry()
local runner = telem:make_runner()

if type_filter:match('E') then
    runner:listen_for_event(nil, function(message)
        assert(message.type == PayloadType.EVENT)
        local host = message.host_id .. ':' .. message.host_name
        local match_id = id_filter == nil or tostring(message.host_id) == id_filter
        local match_host = host_filter == nil or message.host_name == host_filter
        if match_id and match_host then
            if id_filter == nil and host_filter == nil then
                write('[' .. host .. '] ')
            end
            print('E', message.event.type, message.event.message, json.encode(message.event.data))
        end
    end)
end

if type_filter:match('A') then
    runner:listen_for_alert(nil, function(message)
        assert(message.type == PayloadType.ALERT)
        local host = message.host_id .. ':' .. message.host_name
        local match_id = id_filter == nil or tostring(message.host_id) == id_filter
        local match_host = host_filter == nil or message.host_name == host_filter
        if match_id and match_host then
            if id_filter == nil and host_filter == nil then
                write('[' .. host .. '] ')
            end
            print('A', message.alert.type, message.alert.message, json.encode(message.alert.data))
        end
    end)
end

runner:run()
