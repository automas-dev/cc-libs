local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('kv.server')

local json = require 'cc-libs.util.json'

local table_copy = require 'cc-libs.util.table_copy'

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

---@class KVItem
---@field key string
---@field value string
---@field set_by_host string
---@field set_by_id number
---@field last_update string os.time of the creation or last update
---@field history KVItem[]

---Create a new ProtocolServer for a map
---@param hostname string
---@param kv_store_dir string
---@return ProtocolSerer
local function KVServer(hostname, kv_store_dir)
    local server = ProtocolServer:new('kv_store', hostname)

    fs.makeDir(kv_store_dir)
    log:debug('Created kv store dir', kv_store_dir)

    ---Read a value from the kv store directory
    ---@param key string
    ---@return KVItem? entry
    local function read_entry(key)
        log:debug('Read', key)

        local kv_path = fs.combine(kv_store_dir, key .. '.json')
        if fs.exists(kv_path) then
            local file = io.open(kv_path, 'r')
            if file == nil then
                log:error('Failed to open file', kv_path)
                return
            end
            local value = file:read('a')
            local success, entry = pcall(json.decode, value)
            if not success then
                log:error('Failed to decode entry at', kv_path)
                return
            end
            file:close()
            return entry
        end
    end

    ---Assign a value to a key in the kv store directory
    ---@param key string
    ---@param value string
    ---@param set_by_id number
    ---@param set_by_host string
    ---@return boolean success
    local function update_entry(key, value, set_by_id, set_by_host)
        log:debug('Update', key, 'to value', value, 'from', set_by_id, set_by_host)

        local now = os.epoch('utc') / 1000
        local now_datetime = os.date('%Y-%m-%dT%H:%M:%S', now)
        ---@cast now_datetime string

        local entry = read_entry(key)

        if entry == nil then
            entry = {
                key = key,
                value = value,
                set_by_id = set_by_id,
                set_by_host = set_by_host,
                last_update = now_datetime,
                history = {},
            }
        else
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

        local kv_path = fs.combine(kv_store_dir, key .. '.json')
        local file = io.open(kv_path, 'w')
        if file == nil then
            log:error('Failed to open', kv_path)
            return false
        end

        file:write(json.encode(entry))
        file:close()

        return true
    end

    server:route(
        'set',
        {
            request_model = Schema:new({
                entry = {
                    type = FieldType.OBJECT,
                    object = {
                        key = { type = FieldType.STRING },
                        value = { type = FieldType.STRING },
                        set_by_host = { type = FieldType.STRING },
                        set_by_id = { type = FieldType.INTEGER },
                    },
                },
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
            local entry = read_entry(body.key)

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
                    optional = true,
                    value = {
                        type = FieldType.OBJECT,
                        object = {
                            key = { type = FieldType.STRING },
                            value = { type = FieldType.STRING },
                            set_by_host = { type = FieldType.STRING },
                            set_by_id = { type = FieldType.INTEGER },
                            last_update = { type = FieldType.STRING },
                        },
                    },
                },
            }),
        },
        ---@param request Request
        function(request)
            local body = request.message.body
            ---@cast body table
            local entry = read_entry(body.key)

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

    return server
end

return {
    KVServer = KVServer,
}
