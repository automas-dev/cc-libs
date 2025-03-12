package.path = '../?.lua;../?/init.lua;' .. package.path

local logging = require 'cc-libs.util.logging'
logging.basic_config {
    filepath = 'logs/ask_map.log',
}

local log = logging.get_logger('ask_map')

peripheral.find('modem', rednet.open)

local host = rednet.lookup('map')
if host == nil then
    log:error('host was nil')
    error('host was nil')
end

rednet.send(host, {
    system = 'waypoint',
    method = 'add',
    location = { x = 1, y = 2, z = 3 },
    name = 'wp1',
}, 'map')
