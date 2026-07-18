local map_map = require 'cc-libs.map.map'
local map_client = require 'cc-libs.map.client'
local map_server = require 'cc-libs.map.server'

return {
    Map = map_map.Map,
    MapClient = map_client.MapClient,
    MapServer = map_server.MapServer,
}
