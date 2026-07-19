-- Setup import paths
package.path = '../../?.lua;../../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.DEBUG,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/kv_store.log',
}
local log = logging.get_logger('main')

local table_copy = require 'cc-libs.util.table_copy'

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

local server = ProtocolServer:new('kv_store', 'server')

---@class KVStoreItem
---@field key string
---@field value string
---@field set_by_host string
---@field set_by_id number
---@field last_update string os.time of the creation or last update
---@field history KVStoreItem[]

---@type { [string] : KVStoreItem }
local temp_kv_store = {}

local function update_entry(key, value, set_by_id, set_by_host)
    log:debug('Update', key, 'to value', value, 'from', set_by_id, set_by_host)
    local store = temp_kv_store

    local now = os.epoch('utc') / 1000
    local now_datetime = os.date('%Y-%m-%dT%H:%M:%S', now)
    ---@cast now_datetime string

    if store[key] == nil then
        store[key] = {
            key = key,
            value = value,
            set_by_id = set_by_id,
            set_by_host = set_by_host,
            last_update = now_datetime,
            history = {},
        }
    else
        local entry = store[key]

        -- Get copy of current entry without history
        local history = entry.history
        entry.history = nil
        table.insert(history, table_copy(entry))

        -- New assignment and add back history
        entry.value = value
        entry.set_by_id = set_by_id
        entry.set_by_host = set_by_host
        entry.last_update = now_datetime
        entry.history = history
    end
end

---@type SchemaField
local CreateKVItemField = {
    type = FieldType.OBJECT,
    object = {
        key = { type = FieldType.STRING },
        value = { type = FieldType.STRING },
        set_by_host = { type = FieldType.STRING },
        set_by_id = { type = FieldType.INTEGER },
    },
}

---@type SchemaField
local KVItemField = {
    type = FieldType.OBJECT,
    object = {
        key = { type = FieldType.STRING },
        value = { type = FieldType.STRING },
        set_by_host = { type = FieldType.STRING },
        set_by_id = { type = FieldType.INTEGER },
        last_update = { type = FieldType.STRING },
    },
}

server:route(
    'set',
    {
        request_model = Schema:new({
            entry = CreateKVItemField,
        }),
        response_model = Schema:new({
            err = { type = FieldType.STRING, optional = true },
        }),
    },
    ---@param request Request
    function(request)
        local body = request.message.body
        ---@cast body table
        local entry = body.entry
        update_entry(entry.key, entry.value, entry.set_by_id, entry.set_by_host)
        return request:ok_response({})
    end
)

server:route(
    'get',
    {
        request_model = Schema:new({
            key = { type = FieldType.STRING },
        }),
        response_model = Schema:new({
            found = { type = FieldType.BOOL },
            entry = {
                type = FieldType.OBJECT,
                optional = true,
                object = {
                    key = { type = FieldType.STRING },
                    value = { type = FieldType.STRING },
                    set_by_host = { type = FieldType.STRING },
                    set_by_id = { type = FieldType.INTEGER },
                    last_update = { type = FieldType.STRING },
                },
            },
        }),
    },
    ---@param request Request
    function(request)
        local body = request.message.body
        ---@cast body table
        local entry = temp_kv_store[body.key]

        if entry == nil then
            return request:ok_response({ found = false })
        end

        return request:ok_response({
            found = true,
            entry = {
                key = entry.key,
                value = entry.value,
                set_by_id = entry.set_by_id,
                set_by_host = entry.set_by_host,
                last_update = entry.last_update,
            },
        })
    end
)

server:route(
    'get_history',
    {
        request_model = Schema:new({
            key = { type = FieldType.STRING },
        }),
        response_model = Schema:new({
            found = { type = FieldType.BOOL },
            entry = {
                type = FieldType.OBJECT,
                optional = true,
                object = {
                    key = { type = FieldType.STRING },
                    value = { type = FieldType.STRING },
                    set_by_host = { type = FieldType.STRING },
                    set_by_id = { type = FieldType.INTEGER },
                    last_update = { type = FieldType.STRING },
                },
            },
            history = {
                type = FieldType.ARRAY,
                value = KVItemField,
                optional = true,
            },
        }),
    },
    ---@param request Request
    function(request)
        local body = request.message.body
        ---@cast body table
        local entry = temp_kv_store[body.key]

        if entry == nil then
            return request:ok_response({ found = false })
        end

        return request:ok_response({
            found = true,
            entry = {
                key = entry.key,
                value = entry.value,
                set_by_id = entry.set_by_id,
                set_by_host = entry.set_by_host,
                last_update = entry.last_update,
            },
            history = entry.history,
        })
    end
)

log:catch_errors(server.serve_forever, server)
