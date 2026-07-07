package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/alert_monitor.log',
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

local json = require 'cc-libs.util.json'

local ccl_telemetry = require 'cc-libs.net.telemetry'
local TELEMETRY_PROTOCOL = ccl_telemetry.TELEMETRY_PROTOCOL
local PayloadType = ccl_telemetry.PayloadType

peripheral.find('modem', rednet.open)

while true do
    local id, message = rednet.receive(TELEMETRY_PROTOCOL)
    local success, data = pcall(json.decode, message)
    if not success then
        print('Failed to decode message from ' .. id)
    else
        local host = data['host_id'] .. ':' .. data['host_name']
        local match_id = id_filter == nil or tostring(data['host_id']) ~= id_filter
        local match_host = host_filter == nil or data['host_name'] ~= host_filter
        if match_id and match_host then
            if data._telem_type == PayloadType.EVENT and type_filter:match('E') then
                print('[' .. host .. '] E', data.event.type, data.event.message, json.encode(data.event.data))
            elseif data._telem_type == PayloadType.ALERT and type_filter:match('A') then
                print('[' .. host .. '] A', data.alert.type, data.alert.message, json.encode(data.alert.data))
                -- elseif data._telem_type == PayloadType.STATE  and type_filter:match('S') then
                --     print('[' .. host .. '] S', json.encode(data.state))
            end
        end
    end
end
