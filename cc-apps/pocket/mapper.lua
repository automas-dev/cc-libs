package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_mapper.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local location = Location:new()
local telem = get_telemetry()
telem:set_location(location)

---@type MapClient
local client

local function main()
    client = MapClient:new('server')

    local last = { x = nil, y = nil, z = nil }
    while true do
        local x, y, z = gps.locate(2, false)
        if x == nil or y == nil or z == nil then
            log:warning('Timeout waiting for GPS location')
        else
            x = math.floor(x)
            y = math.floor(y)
            z = math.floor(z)
            if x ~= last.x or y ~= last.y or z ~= last.z then
                local pos = { x = x, y = y, z = z }
                last = pos
                log:debug('Adding node at', pos)
                local node, action = client:add_node(pos)
                if node == nil then
                    log:error('Failed to create node at', pos)
                elseif action == 'added' then
                    log:info('New node created', node.id)
                elseif action == 'exists' then
                    log:debug('Node already exists', node.id)
                end

                -- Add point at feet
                node, action = client:add_node({ x = x, y = y - 1, z = z })
                if node == nil then
                    log:error('Failed to create node at', pos)
                elseif action == 'node added' then
                    log:debug('New node created for feet', node.id)
                elseif action == 'node exists' then
                    log:debug('Node already exists for feet', node.id)
                end
            end
        end
    end
end

local function mark_waypoint()
    while true do
        io.stdout:write('waypoint> ')
        local name = io.stdin:read()
        if name then
            local x, y, z = gps.locate(2, false)
            if x == nil or y == nil or z == nil then
                log:warning('Timeout waiting for GPS location')
            else
                x = math.floor(x)
                y = math.floor(y)
                z = math.floor(z)
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
        end
    end
end

local runner = telem:make_runner()
runner:add_thread('mark_waypoint', false, mark_waypoint)

-- Call main and log an error if raised
runner:add_thread('main', true, log.catch_errors, log, main)
runner:run()
