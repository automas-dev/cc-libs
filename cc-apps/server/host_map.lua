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

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map

local MAP_FILE = 'map.json'

---@type Map
local map

local function load_map()
    map = Map:new()
    if not pcall(map.load, map, MAP_FILE) then
        log:info('Map does not exist, creating')
        map:dump(MAP_FILE)
    else
        log:info('Map loaded from', MAP_FILE)
    end
end

local server = ProtocolServer:new('map', 'server')

---@param request Request
server:route('get', function(request)
    return request:ok_response({
        map = map,
    })
end)

---Validate a waypoint packet
---@param waypoint any
---@return boolean ok
---@return string? reason if not ok
local function validate_waypoint(waypoint)
    if waypoint == nil then
        return false, 'Missing field waypoint'
    elseif type(waypoint) ~= 'table' then
        return false, 'Message is not a table'
    elseif waypoint.name == nil then
        return false, 'Missing field waypoint.name'
    elseif waypoint.pos == nil then
        return false, 'Missing field waypoint.pos'
    elseif waypoint.pos.x == nil or waypoint.pos.y == nil or waypoint.pos.z == nil then
        return false, 'Components of waypoint.pos are nil'
    end
    return true
end

---@param request Request
server:route('add_waypoint', function(request)
    local body = request.message.body
    if type(body) ~= 'table' then
        return request:err_response('Body must be a table')
    end

    local ok, reason = validate_waypoint(body.waypoint)
    if not ok then
        return request:err_response(reason)
    end

    local name = body.waypoint.name
    local pos = body.waypoint.pos

    local exists = map:get_waypoint(name) ~= nil
    local point = map:pos(pos)
    map:add_waypoint(point, name)
    map:dump(MAP_FILE)
    log:info('Added waypoint', name)

    return request:ok_response({ waypoint = point, action = exists and 'waypoint replaced' or 'waypoint added' })
end)

---Validate a node packet
---@param node any
---@return boolean ok
---@return string? reason if not ok
local function validate_node(node)
    if node == nil then
        return false, 'Missing field node'
    elseif type(node) ~= 'table' then
        return false, 'Message is not a table'
    elseif node.pos == nil then
        return false, 'Missing field node.pos'
    elseif node.pos.x == nil or node.pos.y == nil or node.pos.z == nil then
        return false, 'Components of node.pos are nil'
    end
    return true
end

---@param request Request
server:route('add_node', function(request)
    local body = request.message.body
    if type(body) ~= 'table' then
        return request:err_response('Body must be a table')
    end

    local ok, reason = validate_node(body.node)
    if not ok then
        return request:err_response(reason)
    end

    local pos = body.node.pos

    local point = map:get_pos(pos.x, pos.y, pos.z)
    local exists = point ~= nil
    if not exists then
        point = map:pos(pos)
        map:dump(MAP_FILE)
        log:info('Added node', point.id)
    end
    return request:ok_response({ node = point, action = exists and 'node exists' or 'node added' })
    -- return request:ok_response('node exists')
end)

-- Main function
local function main()
    load_map()
    server:serve_forever()
end

-- Call main and log an error if raised
log:catch_errors(main)
