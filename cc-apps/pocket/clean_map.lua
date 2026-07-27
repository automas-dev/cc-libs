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

    local function clear_pos(x, y, z)
        map:unmask_pos(x, y, z)
        local point = map:get_pos(x, y, z)
        if point then
            log:info('Removing point', point.id)
            map:remove_point(point.id)
        else
            log:debug('Point does not exist at', { x = x, y = y, z = z })
        end
        if y >= -51 and y < 59 then
            map:mask_pos(x, y, z)
        end
    end

    log:info('Removing and masking points')
    for y = -51, 61 do
        log:debug('y =', y)
        clear_pos(-54, y, -1079)
        clear_pos(-54, y, -1075)
        clear_pos(-54, y, -1073)
    end
    log:info('Finished removing points')

    local function link_one_way(y1, y2, z, weight)
        weight = weight or 1
        map:unmask_pos(-54, y1, z)
        map:unmask_pos(-54, y2, z)
        p1 = map:point(-54, y1, z)
        p2 = map:point(-54, y2, z)
        log:info('Adding points', p1, p2, 'weight', weight)
        log:debug('Linking points', p1, p2)
        map:dir_link(p1, p2, weight)
    end

    link_one_way(-51, 59, -1073)
    link_one_way(59, -51, -1075)

    map:point(-54, -52, -1073)
    map:point(-54, -53, -1073)

    map:point(-54, -53, -1074)
    map:point(-54, -52, -1074)

    map:point(-54, -53, -1075)
    map:point(-54, -52, -1075)

    map:mask_pos(-54, -51, -1073)
    map:mask_pos(-54, 59, -1073)
    map:mask_pos(-54, -51, -1075)
    map:mask_pos(-54, 59, -1075)

    -- for _, point in pairs(map.graph) do
    --     if point.x >= -53 and point.y >= 51 then
    --         log:info('Remove point', point.id)
    --         map:unmask_point(point.id)
    --         map:remove_point(point.id)
    --     end
    -- end

    -- local path = map:find_path(p1, p2)
    -- assert(path ~= nil)
    -- path = map:find_path(p2, p1)
    -- assert(path == nil)

    -- for _, point in pairs(map.graph) do
    --     local update = false
    --     for pid, w in pairs(point.links) do
    --         if w < 1 then
    --             log:info('Removing weight', w, pid)
    --             point[pid] = nil
    --             update = true
    --         end
    --     end
    --     if update then
    --         map:add_point(point)
    --     end
    -- end
end

log:catch_errors(main)
