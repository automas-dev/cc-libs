local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map.server')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

local ccl_map = require 'cc-libs.map.map'
local Map = ccl_map.Map

---@type SchemaField
local PositionField = {
    type = FieldType.OBJECT,
    object = {
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local PointField = {
    type = FieldType.OBJECT,
    object = {
        id = { type = FieldType.STRING },
        links = { type = FieldType.OBJECT, key = { type = FieldType.STRING }, value = { type = FieldType.FLOAT } },
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local OptionalPointField = {
    type = FieldType.OBJECT,
    optional = true,
    object = {
        id = { type = FieldType.STRING },
        links = { type = FieldType.OBJECT, key = { type = FieldType.STRING }, value = { type = FieldType.FLOAT } },
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local MapField = {
    type = FieldType.OBJECT,
    object = {
        graph = {
            type = FieldType.OBJECT,
            key = { type = FieldType.STRING },
            value = PointField,
        },
        waypoints = {
            type = FieldType.OBJECT,
            key = { type = FieldType.STRING },
            value = { type = FieldType.STRING },
        },
    },
}

---Create a new ProtocolServer for a map
---@param hostname string
---@param map_path string
---@return ProtocolSerer
local function MapServer(hostname, map_path)
    local server = ProtocolServer:new('map', hostname)

    local map = Map:new()
    if not pcall(map.load, map, map_path) then
        log:info('Map does not exist, creating')
    else
        log:info('Map loaded from', map_path)
    end

    server:route(
        'get',
        {
            response_model = Schema:new({
                map = MapField,
            }),
        },
        ---@param request Request
        function(request)
            return request:ok_response({
                map = map,
            })
        end
    )

    server:route(
        'add_node',
        {
            request_model = Schema:new({
                pos = PositionField,
            }),
            response_model = Schema:new({
                action = { type = FieldType.STRING },
                node = PointField,
            }),
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local pos = body.pos

            local point = map:get_pos(pos.x, pos.y, pos.z)
            local exists = point ~= nil
            if not exists then
                point = map:pos(pos)
                map:dump(map_path)
                log:info('Added node', point.id)
            end

            return request:ok_response({ node = point, action = exists and 'exists' or 'added' })
        end
    )

    server:route(
        'add_waypoint',
        {
            request_model = Schema:new({
                name = { type = FieldType.STRING },
                pos = PositionField,
            }),
            response_model = Schema:new({
                waypoint = PointField,
                action = { type = FieldType.STRING },
            }),
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local name = body.name
            local pos = body.pos

            local exists = map:get_waypoint(name) ~= nil
            local point = map:pos(pos)
            map:add_waypoint(name, point)
            map:dump(map_path)
            log:info('Added waypoint', name)

            return request:ok_response({ waypoint = point, action = exists and 'replaced' or 'added' })
        end
    )

    server:route(
        'get_waypoint',
        {
            request_model = Schema:new({
                name = { type = FieldType.STRING },
            }),
            response_model = Schema:new({
                found = { type = FieldType.BOOL },
                waypoint = OptionalPointField,
                name = { type = FieldType.STRING, optional = true },
            }),
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local name = body.name

            local point = map:get_waypoint(name)
            if point == nil then
                return request:ok_response({ found = false })
            end

            return request:ok_response({ found = true, waypoint = point, name = name })
        end
    )

    server:route(
        'list_waypoints',
        {
            response_model = Schema:new({
                waypoints = {
                    type = FieldType.ARRAY,
                    value = {
                        type = FieldType.OBJECT,
                        object = {
                            name = { type = FieldType.STRING },
                            waypoint = PointField,
                        },
                    },
                },
            }),
        },
        ---@param request Request
        function(request)
            local waypoints = {}

            for name, pid in pairs(map.waypoints) do
                table.insert(waypoints, {
                    name = name,
                    waypoint = map:get_point(pid),
                })
            end

            return request:ok_response({ waypoints = waypoints })
        end
    )

    return server
end

return {
    MapServer = MapServer,
}
