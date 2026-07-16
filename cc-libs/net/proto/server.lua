local logging = require 'cc-libs.util.logging'

local proto_util = require 'cc-libs.net.proto.util'
local open_rednet = proto_util.open_rednet

local proto_model = require 'cc-libs.net.proto.model'
local Request = proto_model.Request
local Response = proto_model.Response
local ResponseStatus = proto_model.ResponseStatus
local validate_message = proto_model.validate_message

---@alias Route fun(Request): Response

---@class ProtocolSerer
---@field protocol string
---@field hostname string
---@field response_protocol string
---@field routes { [string]: Route }
---@field logger Logger
local ProtocolServer = {}

---Create a new ProtocolServer object
---@param protocol string
---@param hostname string
---@return ProtocolSerer
function ProtocolServer:new(protocol, hostname)
    local o = {
        protocol = protocol,
        hostname = hostname,
        response_protocol = protocol .. '_response',
        routes = {},
        logger = logging.get_logger(table.concat({ 'proto_server', protocol, hostname }, '.')),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a route to the server
---@param path string
---@param fn Route
function ProtocolServer:route(path, fn)
    self.logger:debug('Adding route for', path)
    self.routes[path] = fn
end

---Send a single response
---@param response Response
function ProtocolServer:send(response)
    self.logger:trace('Sending response', response)
    rednet.send(response.recipient, {
        id = response.request.message.id,
        path = response.request.message.path,
        status = response.status,
        body = response.message,
    }, self.response_protocol)
end

---Handle a single request
---@param request Request
function ProtocolServer:handle_request(request)
    self.logger:debug('Handling request', request)

    local path = request.message.path

    local route_fn = self.routes[path]
    if route_fn == nil then
        self.logger:trace('Route not found for path', path)
        self:send(request:not_found_response('Route does not exist for path ' .. path))
        return
    end

    self.logger:trace('Calling function for path', path)
    local response = route_fn(request)
    self.logger:trace('Route function returned', response)
    self:send(response)
end

---Wait for connections and serve responses using the attached routes.
---This function will return if it receives a terminate os event.
function ProtocolServer:serve_forever()
    open_rednet()
    rednet.host(self.protocol, self.hostname)
    self.logger:info('Registered host', self.hostname, 'for protocol', self.protocol)
    while true do
        local event, sender, message, protocol = os.pullEventRaw()
        if event == 'rednet_message' and sender ~= nil and protocol == self.protocol then
            self.logger:trace('rednet message', sender, message, protocol)
            local ok, reason = validate_message(message)
            if not ok then
                ---@cast reason string
                self.logger:trace('Invalid message', reason)
                rednet.send(sender, reason, self.response_protocol)
            else
                local request = Request:new(sender, message, protocol)
                local success, err = pcall(self.handle_request, self, request)
                if not success then
                    self.logger:error('Error processing request', err, { request = request })
                end
            end
        elseif event == 'terminate' then
            self.logger:debug('Terminating')
            break
        end
    end
    rednet.unhost(self.protocol)
    self.logger:info('Unregister protocol', self.protocol)
end

return {
    ProtocolServer = ProtocolServer,
}
