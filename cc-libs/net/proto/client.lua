local logging = require 'cc-libs.util.logging'

local proto_util = require 'cc-libs.net.proto.util'
local open_rednet = proto_util.open_rednet

local proto_model = require 'cc-libs.net.proto.model'
local ResponseStatus = proto_model.ResponseStatus
local validate_message = proto_model.validate_message

local uuid = require 'cc-libs.util.uuid'

---@class ProtocolClient
---@field protocol string
---@field server_hostname string
---@field server_id number
---@field response_protocol string
---@field timeout number?
---@field logger Logger
local ProtocolClient = {}

---Create a new ProtocolClient object
---@param protocol string
---@param server_hostname string server hostname
---@param timeout? number
---@return ProtocolClient
function ProtocolClient:new(protocol, server_hostname, timeout)
    local log = logging.get_logger(table.concat({ 'proto_client', protocol, server_hostname }, '.'))
    open_rednet()
    log:trace('Lookup protocol', protocol, 'on host', server_hostname)
    local server_id = rednet.lookup(protocol, server_hostname)
    if server_id == nil then
        error('No server found for protocol ' .. protocol .. ' hostname ' .. server_hostname)
    end
    log:trace('Got server id', server_id)
    local o = {
        protocol = protocol,
        server_hostname = server_hostname,
        server_id = server_id,
        response_protocol = protocol .. '_response',
        timeout = timeout,
        logger = log,
    }
    setmetatable(o, self)
    self.__index = self
    log:debug('Got server id', server_id, 'for protocol', protocol, 'hostname', server_hostname)
    return o
end

---Send a request to the server
---@param path string
---@param body? string|table
---@param timeout? number
---@return boolean success
---@return ResponseStatus|nil status
---@return string|table|nil response
function ProtocolClient:request(path, body, timeout)
    if timeout == nil then
        timeout = self.timeout
    end

    local request_id = uuid()
    self.logger:trace('Request id is', request_id)

    if
        not rednet.send(self.server_id, {
            id = request_id,
            path = path,
            body = body,
        }, self.protocol)
    then
        self.logger:trace('Failed to send request to', self.server_id)
        return false
    end

    -- Similar to rednet.receive
    local timer = nil
    local event_filter = nil
    if timeout then
        timer = os.startTimer(timeout)
        self.logger:trace('Setting timer for timeout of', timeout)
    else
        self.logger:trace('No timeout')
        event_filter = 'rednet_message'
    end

    while true do
        local event, p1, p2, p3 = os.pullEvent(event_filter)
        if event == 'rednet_message' then
            local sender, message, protocol = p1, p2, p3
            if sender ~= nil and protocol == self.response_protocol then
                self.logger:trace('rednet message', sender, message, protocol)
                if not validate_message(message, true) then
                    self.logger:trace('Invalid message received')
                    return false
                end
                ---@cast message ResponseMessage
                if message.id == request_id then
                    self.logger:trace('Got valid response', message)
                    return message.status == ResponseStatus.OK, message.status, message.body
                else
                    self.logger:trace('Response was for another request', message.id)
                end
            end
        elseif event == 'timer' then
            if p1 == timer then
                self.logger:trace('Timeout waiting for response for path', path)
                return false
            end
        end
    end
end

return {
    ProtocolClient = ProtocolClient,
}
