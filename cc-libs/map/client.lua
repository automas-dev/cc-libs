local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map.client')

local ccl_map = require 'cc-libs.map.map'
local Map = ccl_map.Map

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolClient = ccl_proto.ProtocolClient

---@class MapClient
---@field client ProtocolClient
local MapClient = {}

---Create a new Client object
---@param hostname string
---@return MapClient
function MapClient:new(hostname)
    local o = {
        client = ProtocolClient:new('map', hostname, 5),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Get the full map from server
---@return Map? map nil if there was an error
function MapClient:get_map()
    local success, status, resp = self.client:request('get')
    if success then
        ---@cast resp table
        local map = Map:new()
        map:from_table(resp.map)
        return map
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
end

---Add a node to the map, returns the node and if it was created or already exists
---@param pos Vec3|Point
---@return Point? node the node or nil for error
---@return string? action if the node was added or already exists
function MapClient:add_node(pos)
    local success, status, resp = self.client:request('add_node', {
        pos = pos,
    })
    if success then
        ---@cast resp table
        return resp.node, resp.action
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
end

---Add a waypoint to the map, returns waypoint and if it was created or already exists
---@param name string
---@param pos Vec3|Point
---@return Point? waypoint the waypoint or nil for error
---@return string? action if the waypoint was added or already exists
function MapClient:add_waypoint(name, pos)
    local success, status, resp = self.client:request('add_waypoint', {
        name = name,
        pos = pos,
    })
    if success then
        ---@cast resp table
        return resp.waypoint, resp.action
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
end

return {
    MapClient = MapClient,
}
