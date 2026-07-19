package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/get_waypoint.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('kv_client', 'Get a waypoint from the map server')
parser:add_arg('name', { help = 'waypoint name' })
local args = parser:parse_args({ ... })

local name = args.name

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient

local function main()
    client = MapClient:new('server')

    local point = client:get_waypoint(name)
    if point == nil then
        log:error('Failed to find waypoint', name)
    else
        log:info('name', point)
    end
end

log:catch_errors(main)
