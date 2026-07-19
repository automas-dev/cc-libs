package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_waypoint.log',
}
local log = logging.get_logger('main')

-- TODO argparse commands to get and set waypoints, have option to use gps

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient

local GPS_TIMEOUT = 2

local function main()
    client = MapClient:new('server')

    write('name> ')
    local name = read()
    write('x> ')
    local x = tonumber(read())
    write('y> ')
    local y = tonumber(read())
    write('z> ')
    local z = tonumber(read())

    local pos = { x = x, y = y, z = z }
    log:info('Creating waypoint', name, 'at', pos)
    local waypoint, action = client:add_waypoint(name, pos)
    if waypoint == nil then
        log:error('Failed to create waypoint', name, 'at', pos)
    elseif action == 'added' then
        log:info('New waypoint created', waypoint.id)
    elseif action == 'replaced' then
        log:info('Waypoint replaced', waypoint.id)
    end
end

log:catch_errors(main)
