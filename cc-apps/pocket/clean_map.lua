package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/clean_map.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient
local Map = ccl_map.Map

local function main()
    local client = MapClient:new('server')
    local map = Map:new(client)

    -- log:info('Removing points')

    -- for y = -53, 61 do
    --     log:debug('y =', y)
    --     local point = map:get_pos(-54, y, -1079)
    --     if point then
    --         log:info('Removing point', point.id)
    --         map:remove_point(point.id)
    --     else
    --         log:debug('Point does not exist at y =', y)
    --     end
    -- end
    -- log:info('Finished removing points')

    log:info('Adding points')
    local p1 = map:point(-54, 59, -1075)
    local p2 = map:point(-54, -53, -1075)
    log:info('Linking points')
    map:dir_link(p1, p2, 2)
    log:info('Done!')

    local path = map:find_path(p1, p2)
    assert(path ~= nil)
    path = map:find_path(p2, p1)
    assert(path == nil)
end

log:catch_errors(main)
