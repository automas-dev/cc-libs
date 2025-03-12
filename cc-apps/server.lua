package.path = '../?.lua;../?/init.lua;' .. package.path

local json = require 'cc-libs.util.json'

local logging = require 'cc-libs.util.logging'
logging.basic_config {
    filepath = 'logs/server.log',
    machine_filepath = 'logs/server.log.json',
}

local log = logging.get_logger('server')

peripheral.find('modem', rednet.open)

local proto_handler = {}

---@param sender number
---@param message {system: string, method: string}
function proto_handler.map(sender, message)
    print('Got message ' .. json.encode(message))
    if message['system'] == 'waypoint' then
        if message['method'] == 'add' then
            print('Add waypoint ' .. message['name'] .. ' at ' .. json.encode(message['location']))
        end
    end
end

local function run_server()
    for proto in pairs(proto_handler) do
        rednet.host(proto, 'server')
    end
    while true do
        ---@type string, number, any, string?
        local event, sender, message, protocol = os.pullEvent('rednet_message')
        log:trace('Received message for protocol', protocol, 'from sender', sender, 'message:', json.encode(message))
        local handler = proto_handler[protocol]
        if handler ~= nil then
            log:debug('Found handler for protocol ', protocol)
            local success, err = pcall(handler, sender, message)
            if not success then
                log:error('Error in handler for protocol ', protocol, ' : ', err)
            end
        else
            log:trace('No handler for protocol ', protocol)
        end
    end
end

while true do
    log:info('Starting server')
    local success, err = pcall(run_server)
    if success then
        log:debug('Server exited with success')
        break
    else
        log:error('Server crashed with error ', err)
        os.sleep(1)
    end
end

log:info('Server closing')
