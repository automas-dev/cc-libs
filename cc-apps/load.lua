-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/branch_mine.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map
local MapClient = ccl_map.MapClient

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local telem = get_telemetry()

local function main()
    while true do
        local map_client = MapClient:new('server')
        log:info('Load map')
        local map = Map:new(map_client)
        log:info('Do math')
        local i = 1
        while i < 50000000 do
            i = i + 1
        end
        log:info('Talk')
        local t = {}
        for _ = 1, 1000 do
            table.insert(t, _)
        end
        for _ = 1, 100 do
            telem:send_event('talk', 'talk')
        end
    end
end

-- log:catch_errors(main)
telem:run_parallel_with('main', log:wrap_fn(main))
