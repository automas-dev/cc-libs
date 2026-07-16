package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_mapper.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local uuid = require 'cc-libs.util.uuid'

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local location = Location:new()
local telem = get_telemetry()
telem:set_location(location)

local map_host

local function main()
    peripheral.find('modem', rednet.open)
    map_host = rednet.lookup('map', 'server')
    if map_host == nil then
        log:error('Failed to find map host')
        return
    end
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
                local request = {
                    id = uuid(),
                    ask = 'add_node',
                    node = {
                        pos = pos,
                    },
                }
                rednet.send(map_host, json.encode(request), 'map')
                local sender, message = rednet.receive('map_response', 5)
                if sender == nil then
                    log:warning('Timeout waiting for response from map server')
                else
                    local response = json.decode(message)
                    if response.id ~= nil and response.id ~= request.id then
                        log:error('Got someone elses response')
                    elseif not response.ok then
                        log:error('Server responded with error', response.err)
                    elseif response.message == 'node added' then
                        log:info('New node created', response.node.id)
                    elseif response.message == 'node exists' then
                        log:debug('New already exists', response.node.id)
                    else
                        log:info('Response from map server', response.message)
                    end
                end
                -- Add point at feet
                request.id = uuid()
                request.node.pos.y = request.node.pos.y - 1
                rednet.send(map_host, json.encode(request), 'map')
                sender, message = rednet.receive('map_response', 5)
                if sender == nil then
                    log:warning('Timeout waiting for response from map server')
                else
                    local response = json.decode(message)
                    if response.id ~= nil and response.id ~= request.id then
                        log:error('Got someone elses response')
                    elseif not response.ok then
                        log:error('Server responded with error', response.err)
                    elseif response.message == 'node added' then
                        log:debug('New node created for feet', response.node.id)
                    elseif response.message == 'node exists' then
                        log:debug('New already exists for feet', response.node.id)
                    else
                        log:debug('Response from map server', response.message)
                    end
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
                local request = {
                    id = uuid(),
                    ask = 'add_waypoint',
                    waypoint = {
                        name = name,
                        pos = pos,
                    },
                }
                rednet.send(map_host, json.encode(request), 'map')
                local sender, message = rednet.receive('map_response', 5)
                if sender == nil then
                    log:warning('Timeout waiting for response from map server')
                else
                    local response = json.decode(message)
                    if response.id ~= nil and response.id ~= request.id then
                        log:error('Got someone elses response')
                    elseif not response.ok then
                        log:error('Server responded with error', response.err)
                    else
                        log:info('Response from map server', response.message)
                    end
                end
            end
        end
    end
end

local runner = telem:make_runner()
runner:add_thread('mark_waypoint', false, mark_waypoint)

-- Call main and log an error if raised
telem:run_parallel_with('main', log.catch_errors, log, main)
