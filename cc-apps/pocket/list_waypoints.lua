package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/list_waypoints.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient

local function main()
    client = MapClient:new('server')

    local waypoints = client:list_waypoints()
    if waypoints == nil then
        log:error('Failed to get waypoints from server')
    else
        for _, waypoint in ipairs(waypoints) do
            print(waypoint.name, waypoint.waypoint.id)
        end
    end
end

log:catch_errors(main)
