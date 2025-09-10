package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_status.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('status', 'Get status of a computer or turtle')
parser:add_arg('id', { help = 'computer or turtle id' })
local args = parser:parse_args({ ... })

local host_id = tonumber(args.id)

local function run()
    peripheral.find('modem', rednet.open)

    log:debug('Request report')
    rednet.broadcast(json.encode({ id = host_id }), 'report')

    local id, message = rednet.receive('mainframe_response')
    log:debug('Response', message)

    local success, data = pcall(json.decode, message)
    log:debug('Finish decode')
    if not success then
        log:fatal('Failed to decode message from', id)
        return
    end

    if not data.ok then
        log:error('Error response', data.err)
    else
        local status = data.status
        print('Host', status.host_id, ':', status.host_name)
        if status.fuel_level then
            print('Fuel level', status.fuel_level)
        end
        if status.position then
            print('Position', status.position.x, status.position.y, status.position.z)
        end
        print('Last update -', status.status_age, 's')
    end
end

log:catch_errors(run)
