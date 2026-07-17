-- Setup import paths
package.path = '../../?.lua;../../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/server_host_map.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local MapServer = ccl_map.MapServer

local MAP_FILE = 'map.json'

-- Main function
local function main()
    local server = MapServer('server', MAP_FILE)
    server:serve_forever()
end

-- Call main and log an error if raised
log:catch_errors(main)
