package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/kv_client.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('kv_client', 'Get or set a value from the kv server')
parser:add_arg('op', { help = 'get or set' })
parser:add_arg('key', { help = 'key of entry' })
parser:add_arg('value', { help = 'value if operations is set', required = false })
local args = parser:parse_args({ ... })

local id_filter = args.id
local host_filter = args.host
local type_filter = args.types or 'EAS'

log:info('Starting with args', args)

local json = require 'cc-libs.util.json'

local ccl_telemetry = require 'cc-libs.net.telemetry'
local TELEMETRY_PROTOCOL = ccl_telemetry.TELEMETRY_PROTOCOL
local PayloadType = ccl_telemetry.PayloadType

local ccl_proto_util = require 'cc-libs.net.proto.util'

local function main()
    ccl_proto_util.open_rednet()

    while true do
        local id, message = rednet.receive(TELEMETRY_PROTOCOL)
        local success, data = pcall(json.decode, message)
        if not success then
            log:warning('Failed to decode message from ' .. id)
        else
            local host = data['host_id'] .. ':' .. data['host_name']
            local match_id = id_filter == nil or tostring(data['host_id']) == id_filter
            local match_host = host_filter == nil or data['host_name'] == host_filter
            if match_id and match_host then
                if id_filter == nil and host_filter == nil then
                    write('[' .. host .. '] ')
                end
                if data._telem_type == PayloadType.EVENT and type_filter:match('E') then
                    print('E', data.event.type, data.event.message, json.encode(data.event.data))
                elseif data._telem_type == PayloadType.ALERT and type_filter:match('A') then
                    print('A', data.alert.type, data.alert.message, json.encode(data.alert.data))
                    -- elseif data._telem_type == PayloadType.STATE  and type_filter:match('S') then
                    --     print('[' .. host .. '] S', json.encode(data.state))
                end
            end
        end
    end
end

log:catch_errors(main)
