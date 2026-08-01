package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/telemetry_monitor.log',
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
local TELEMETRY_PROTOCOL = ccl_telemetry.TELEMETRY_PROTOCOL
local PayloadType = ccl_telemetry.PayloadType

local ccl_net_util = require 'cc-libs.net.util'

local function main()
    assert(ccl_net_util.open_rednet())

    while true do
        local id, message = rednet.receive(TELEMETRY_PROTOCOL)
        assert(type(message) == 'table')
        local host = message['host_id'] .. ':' .. message['host_name']
        local match_id = id_filter == nil or tostring(message['host_id']) == id_filter
        local match_host = host_filter == nil or message['host_name'] == host_filter
        if match_id and match_host then
            if id_filter == nil and host_filter == nil then
                write('[' .. host .. '] ')
            end
            if message._telem_type == PayloadType.EVENT and type_filter:match('E') then
                print('E', message.event.type, message.event.message, json.encode(message.event.data))
            elseif message._telem_type == PayloadType.ALERT and type_filter:match('A') then
                print('A', message.alert.type, message.alert.message, json.encode(message.alert.data))
                -- elseif data._telem_type == PayloadType.STATE  and type_filter:match('S') then
                --     print('[' .. host .. '] S', json.encode(data.state))
            end
        end
    end
end

log:catch_errors(main)
