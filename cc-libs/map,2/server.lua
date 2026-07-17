local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map')

local json = require 'cc-libs.util.json'

---@class MapServer
---@field map Map
local MapServer = {}

---Create a new Server object
---@param map Map
---@return MapServer
function MapServer:new(map)
    local o = {
        map = map,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Encode `response` in json and send to `recipient` on the map response protocol
---@param recipient number
---@param response any
---@return boolean success
function MapServer:send_response(recipient, response)
    local ok, message = pcall(json.encode, response)
    if not ok then
        log:error('Failed to encode response in json', message)
        return false
    end
    if not rednet.send(recipient, message, MAP_RESPONSE_PROTOCOL) then
        log:warning('Failed to send response to recipient', recipient)
        return false
    end
    return true
end

---Handle a single message from sender
---@param recipient number
---@param message any
function MapServer:handle_message(recipient, message)
    local ok, request = pcall(json.decode, message)
    if not ok then
        self:send_response(recipient, { ok = false, err = 'Invalid Message' })
        return
    end

    if request.id == nil then
        self:send_response(recipient, { ok = false, err = 'Missing field id' })
        return
    end

    if request.ask == nil then
        self:send_response(recipient, { ok = false, err = 'Missing field ask' })
        return
    end

    if request.ask == 'get' then
        self:send_response(recipient, {
            ok = true,
            request_id = request.id,
            map = self.map,
        })
    elseif request.ask == 'add_waypoint' then
        if request.waypoint == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint',
            })
            return
        end

        local name = request.waypoint.name
        if name == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.name',
            })
            return
        end

        local pos = request.waypoint.pos
        if pos == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos',
            })
            return
        end

        if pos.x == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.x',
            })
            return
        elseif pos.y == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.y',
            })
            return
        elseif pos.z == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.z',
            })
            return
        end

        local exists = self.map:get_waypoint(name) ~= nil
        local point = self.map:pos(pos)
        self.map:add_waypoint(point, name)
        self.map:dump(MAP_FILE)
        log:info('Added waypoint', name)

        self:send_response(recipient, {
            ok = true,
            id = request.id,
            message = exists and 'waypoint replaced' or 'waypoint added',
        })
    elseif request.ask == 'add_node' then
        if request.node == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field node',
            })
            return
        end

        local pos = request.node.pos
        if pos == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos',
            })
            return
        end

        if pos.x == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.x',
            })
            return
        elseif pos.y == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.y',
            })
            return
        elseif pos.z == nil then
            self:send_response(recipient, {
                ok = false,
                id = request.id,
                err = 'Missing field waypoint.pos.z',
            })
            return
        end

        local point = self.map:get_pos(pos.x, pos.y, pos.z)
        if point == nil then
            point = self.map:pos(pos)
            self.map:dump(MAP_FILE)
            log:info('Added node', point.id)

            self:send_response(recipient, {
                ok = true,
                id = request.id,
                message = 'node added',
                node = point,
            })
        else
            self:send_response(recipient, {
                ok = true,
                id = request.id,
                message = 'node exists',
                node = point,
            })
        end
    else
        self:send_response(recipient, {
            ok = false,
            id = request.id,
            err = 'Unknown ask',
        })
    end
end

function MapServer:serve_forever()
    log:info('Serving forever')
    while true do
        local sender, message, protocol = rednet.receive(MAP_PROTOCOL)
        if sender ~= nil then
            log:trace('Got message from sender', sender, { message = message, protocol = protocol })
            if protocol ~= MAP_PROTOCOL then
                self:send_response(sender, { ok = false, err = 'Invalid Protocol' })
            else
                local success = log:catch_errors(self.handle_message, self, sender, message)
                if not success then
                    self:send_response(sender, { ok = false, err = 'Server Error' })
                end
            end
        end
    end
end

return {
    MapServer = MapServer,
}
