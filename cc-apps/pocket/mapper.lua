package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_mapper.log',
}
local log = logging.get_logger('main')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolClient = ccl_proto.ProtocolClient

local json = require 'cc-libs.util.json'

local uuid = require 'cc-libs.util.uuid'

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local location = Location:new()
local telem = get_telemetry()
telem:set_location(location)

local client

local function main()
    client = ProtocolClient:new('map', 'server')

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
                -- Add point at head
                local success, status, response = client:request('add_node', { node = { pos = pos } }, 5)
                if not success then
                    log:error('Server responded with error', response)
                elseif response == nil or type(response) ~= 'table' then
                    log:warning('Unknown response from map server', response)
                elseif response.action == 'node added' then
                    log:info('New node created', response.node.id)
                elseif response.action == 'node exists' then
                    log:debug('New already exists', response.node.id)
                else
                    log:warning('Unknown response from map server', response)
                end

                -- Add point at feet
                success, status, response = client:request('add_node', {
                    node = { pos = { x = x, y = y - 1, z = z } },
                }, 5)
                if not success then
                    log:error('Server responded with error', response)
                elseif response == nil or type(response) ~= 'table' then
                    log:warning('Unknown response from map server', response)
                elseif response.action == 'node added' then
                    log:debug('New node created for feet', response.node.id)
                elseif response.action == 'node exists' then
                    log:debug('New already exists for feet', response.node.id)
                else
                    log:warning('Unknown response from map server', response)
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
                local success, status, response =
                    client:request('add_waypoint', { waypoint = { name = name, pos = pos } }, 5)
                if not success then
                    log:error('Server responded with error', response)
                elseif response == nil or type(response) ~= 'table' then
                    log:warning('Unknown response from map server', response)
                elseif response.action == 'waypoint added' then
                    log:info('New waypoint created', response.waypoint.id)
                elseif response.action == 'waypoint replaced' then
                    log:debug('Replaced exists waypoint', response.waypoint.id)
                else
                    log:warning('Unknown response from map server', response)
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
