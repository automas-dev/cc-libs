local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map.server')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local model = require 'cc-libs.map.model'

local ccl_map = require 'cc-libs.map.map'
local Map = ccl_map.Map

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
            response_model = model.GetResponseSchema,
        },
        ---@param request Request
        function(request)
            return request:ok_response({
                map = {
                    graph = map.graph,
                    waypoint = map.waypoints,
                    update_mask = map.update_mask,
                },
            })
        end
    )

    server:route(
        'add_node',
        {
            request_model = model.AddNodeRequestSchema,
            response_model = model.AddNodeResponseSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local pos = body.pos

            local point = map:get_pos(pos.x, pos.y, pos.z)
            local updated = false

            if not point then
                point = map:pos(pos)
                updated = true
            end

            local links = body.links
            if links then
                for k, v in pairs(links) do
                    point.links[k] = v
                    updated = true
                end
            end

            if updated then
                log:info('Added node', point.id)
                map:dump(map_path)
            end

            return request:ok_response({ node = point, action = point and 'exists' or 'added' })
        end
    )

    server:route(
        'batch_update',
        {
            request_model = model.BatchUpdateRequestSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local nodes = body.nodes
            local updated = false

            for _, node in ipairs(nodes) do
                local point = map:get_pos(node.x, node.y, node.z)

                if not point then
                    point = map:pos(node)
                    updated = true
                end

                local links = body.links
                if links then
                    for k, v in pairs(links) do
                        point.links[k] = v
                        updated = true
                    end
                end
            end

            log:info('Batch update', #nodes, 'nodes')

            if updated then
                map:dump(map_path)
            end

            return request:ok_response()
        end
    )

    server:route(
        'remove_node',
        {
            request_model = model.RemoveNodeRequestSchema,
            response_model = model.RemoveNodeResponseSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local pid = body.pid

            local point = map:get_point(pid)
            if point then
                map:remove_point(pid)
                log:info('Remove node', pid)
                map:dump(map_path)
            end

            return request:ok_response({ node = point })
        end
    )

    server:route(
        'add_waypoint',
        {
            request_model = model.AddWaypointRequestSchema,
            response_model = model.AddWaypointResponseSchema,
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
            log:info('Added waypoint', name)
            map:dump(map_path)

            return request:ok_response({ waypoint = point, action = exists and 'replaced' or 'added' })
        end
    )

    server:route(
        'get_waypoint',
        {
            request_model = model.GetWaypointRequestSchema,
            response_model = model.GetWaypointResponseSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local name = body.name

            local point = map:get_waypoint(name)
            if not point then
                return request:ok_response({ found = false })
            end

            return request:ok_response({ found = true, waypoint = point, name = name })
        end
    )

    server:route(
        'remove_waypoint',
        {
            request_model = model.RemoveWaypointRequestSchema,
            response_model = model.RemoveWaypointResponseSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local name = body.name

            local point = map:get_waypoint(name)
            if not point then
                return request:ok_response({ found = false })
            end

            return request:ok_response({ found = true, waypoint = point, name = name })
        end
    )

    server:route(
        'list_waypoints',
        {
            response_model = model.ListWaypointsResponseSchema,
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

    server:route(
        'mask',
        {
            request_model = model.MaskRequestSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local pid = body.pid

            map:mask_point(pid)
            log:info('Mask node', pid)
            map:dump(map_path)

            return request:ok_response()
        end
    )

    server:route(
        'unmask',
        {
            request_model = model.UnmaskRequestSchema,
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table

            local pid = body.pid

            map:unmask_point(pid)
            log:info('Unmask node', pid)
            map:dump(map_path)

            return request:ok_response()
        end
    )

    return server
end

return {
    MapServer = MapServer,
}
