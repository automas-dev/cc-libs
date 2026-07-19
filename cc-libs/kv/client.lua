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

---Assign the value for key
---@param key string
---@param value string | number
---@param value_type? string optional type, default will use result of type()
---@return boolean success
---@return string? error
function KVClient:set(key, value, value_type)
    if value_type == nil then
        value_type = type(value)
    end
    assert(
        type(value) == 'string' or type(value) == 'number',
        'value must be a string or number, got ' .. tostring(value_type)
    )
    local success, _, resp = self.client:request('set', {
        entry = {
            key = key,
            value = value,
            value_type = value_type,
            set_by_host = os.getComputerLabel(),
            set_by_id = os.getComputerID(),
        },
    })
    ---@cast resp string?
    return success, resp
end

---Assign the value for key
---@param key string
---@param value number
---@param default? number
---@return KVItem? entry updated entry, nil for error
---@return string? error error if entry is nul
function KVClient:increment(key, value, default)
    assert(type(value) == 'number', 'increment value must ba a number')
    if default ~= nil then
        assert(type(default) == 'number', 'default value must be a number')
    end
    local success, _, resp = self.client:request('increment', {
        entry = {
            key = key,
            value = value,
            value_type = 'number',
            value_default = default,
            set_by_host = os.getComputerLabel(),
            set_by_id = os.getComputerID(),
        },
    })
    if success then
        ---@cast resp table
        return resp.entry
    else
        ---@cast resp string
        return nil, resp
    end
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
        else
            return false
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
        else
            return false
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
        else
            return false
        end
    else
        -- TODO remove this, is it somewhere else?
        log:warning('Got unsuccessful response from server', status, resp)
    end
    return false
end

return {
    KVClient = KVClient,
}
