local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('kv.client')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolClient = ccl_proto.ProtocolClient

---@class KVClient
---@field client ProtocolClient
local KVClient = {}

---Create a new Server object
---@param hostname string
---@param timeout? number defaults to 2
---@return KVClient
function KVClient:new(hostname, timeout)
    local o = {
        client = ProtocolClient:new('kv_store', hostname, timeout or 2),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Get the value for key from the server
---@param key string
---@return boolean success
---@return string? value nil if there was an error
function KVClient:get(key)
    local success, status, resp = self.client:request('get', { key = key })
    if success then
        ---@cast resp table
        if resp.found then
            local entry = resp.entry
            return true, entry.value
        end
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
    return false
end

---Get the entry for key from the server
---@param key string
---@return boolean success
---@return KVItem? entry nil if there was an error
function KVClient:get_entry(key)
    local success, status, resp = self.client:request('get', { key = key })
    if success then
        ---@cast resp table
        if resp.found then
            local entry = resp.entry
            return true, entry
        end
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
    return false
end

---Get the entry for key from the server
---@param key string
---@return boolean success
---@return KVItem? entry nil if there was an error
---@return KVItem[]? history nil if there was an error
function KVClient:get_history(key)
    local success, status, resp = self.client:request('get_history', { key = key })
    if success then
        ---@cast resp table
        if resp.found then
            local entry = resp.entry
            local history = resp.history
            return true, entry, history
        end
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
    return false
end

---Assign the value for key
---@param key string
---@param value string
---@return boolean success
function KVClient:set(key, value)
    local success, status, resp = self.client:request(
        'set',
        { entry = { key = key, value = value, set_by_host = os.getComputerLabel(), set_by_id = os.getComputerID() } }
    )
    if success then
        return true
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
    return false
end

return {
    KVClient = KVClient,
}
