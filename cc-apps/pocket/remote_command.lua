package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/remote_command.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local REMOTE_CONTROL_PROTOCOL = 'remote_control'
local REMOTE_CONTROL_RESPONSE_PROTOCOL = 'remote_control'

local args = { ... }

local function main()
    if #args < 2 then
        print('Usage: remote_command <id> <cmd> [args...]')
        return
    end

    local remote_id = table.remove(args, 1)
    log:debug('Sending remote command to', remote_id)

    peripheral.find('modem', rednet.open)

    rednet.send(remote_id, json.encode({ id = remote_id, command = args }), REMOTE_CONTROL_PROTOCOL)
    local id, message = rednet.receive(REMOTE_CONTROL_RESPONSE_PROTOCOL)

    local success, data = pcall(json.decode, message)
    if not success then
        log:error('Failed to decode message from', id)
    else
        log:info('Command was', data.success)
    end
end

log:catch_errors(main)
