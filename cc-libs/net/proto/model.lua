---@enum ResponseStatus
local ResponseStatus = {
    OK = 'ok',
    ERROR = 'error',
    NOT_FOUND = 'not_found',
}

---@class Message
---@field id string uuid unique to each request
---@field path string
---@field body string | table | nil

---@class ResponseMessage : Message
---@field status ResponseStatus

---Validate that a message has the required fields
---@param message any
---@param is_response? boolean message fields of ResponseMessage
---@return boolean ok
---@return string? reason if not ok
local function validate_message(message, is_response)
    if type(message) ~= 'table' then
        return false, 'Message is not a table'
    elseif message.id == nil then
        return false, 'Missing field id'
    elseif message.path == nil then
        return false, 'Missing field path'
    elseif is_response and message.status == nil then
        return false, 'Missing field status'
    end
    return true
end

---@class Request
---@field sender number
---@field message Message
---@field protocol string?
local Request = {}

---Create a new Request object
---@param sender number
---@param message Message
---@param protocol? string
---@return Request
function Request:new(sender, message, protocol)
    local o = {
        sender = sender,
        message = message,
        protocol = protocol,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@class Response
---@field request Request
---@field recipient number
---@field status ResponseStatus
---@field message any
---@field protocol string?
local Response = {}

---Create a new Response object
---@param request Request
---@param status ResponseStatus
---@param message any
---@return Response
function Response:new(request, status, message)
    local o = {
        request = request,
        recipient = request.sender,
        status = status,
        message = message,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Create a Response with ok status
---@param message any
---@return Response response
function Request:ok_response(message)
    return Response:new(self, ResponseStatus.OK, message)
end

---Create a Response with error status
---@param message any
---@return Response response
function Request:err_response(message)
    return Response:new(self, ResponseStatus.ERROR, message)
end

---Create a Response with not found status
---@param message any
---@return Response response
function Request:not_found_response(message)
    return Response:new(self, ResponseStatus.NOT_FOUND, message)
end

return {
    ResponseStatus = ResponseStatus,
    Response = Response,
    Request = Request,
    validate_message = validate_message,
}
