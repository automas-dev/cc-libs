local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('kv.server')

local json = require 'cc-libs.util.json'

local table_copy = require 'cc-libs.util.table_copy'

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

---@enum KVItemType
local KVItemType = {
    NUMBER = 'number',
    STRING = 'string',
}

---@class KVItem
---@field key string
---@field value string
---@field value_type KVItemType
---@field set_by_host string
---@field set_by_id number
---@field last_update string os.time of the creation or last update
---@field history KVItem[]

---@type SchemaField
local ValueUnionField = {
    type = FieldType.UNION,
    types = {
        { type = FieldType.STRING },
        { type = FieldType.INTEGER },
        { type = FieldType.FLOAT },
    },
}

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
            log:trace('Reading entry for key', key, 'from', kv_path)
            local file = io.open(kv_path, 'r')
            if file == nil then
                log:error('Failed to open file', kv_path)
                return
            end
            local value = file:read('a')
            local entry = json.decode(value)
            file:close()
            log:trace('Finished reading entry for key', key, 'from', kv_path)
            return entry
        else
            log:trace('Entry does not exist for key', key)
        end
    end

    ---Assign a value to a key in the kv store directory
    ---@param key string
    ---@param value string value for set or increment value (positive or negative)
    ---@param value_type KVItemType
    ---@param set_by_id number
    ---@param set_by_host string
    ---@return boolean success
    ---@return string? error
    local function update_entry(key, value, value_type, set_by_id, set_by_host)
        local now = os.epoch('utc') / 1000
        local now_datetime = os.date('%Y-%m-%dT%H:%M:%S', now)
        ---@cast now_datetime string

        local entry = read_entry(key)

        if entry == nil then
            log:trace('Entry is nil for key', key, 'creating new')
            entry = {
                key = key,
                value = value,
                value_type = value_type,
                set_by_id = set_by_id,
                set_by_host = set_by_host,
                last_update = now_datetime,
                history = {},
            }
        else
            log:trace('Entry exists for', key)
            -- Set entries created before this update to string
            if entry.value_type == nil then
                entry.value_type = KVItemType.STRING
                log:trace('Setting default type', entry.value_type)
            end

            -- Get copy of current entry without history
            local history = entry.history
            entry.history = nil
            table.insert(history, table_copy(entry))
            log:trace('Copied history table with', #history, 'entries')

            -- New assignment and add back history
            entry.value = value
            entry.set_by_id = set_by_id
            entry.set_by_host = set_by_host
            entry.last_update = now_datetime
            entry.history = history
        end

        local kv_path = fs.combine(kv_store_dir, key .. '.json')
        log:trace('Writing entry for key', key, 'to', kv_path)
        local file = io.open(kv_path, 'w')
        if file == nil then
            error('Failed to open file ' .. kv_path)
        end

        file:write(json.encode(entry))
        file:close()
        log:trace('Finished writing entry for key', key, 'to', kv_path)

        return true
    end

    ---Increment a value to a key in the kv store directory
    ---@param key string
    ---@param value string value to increment by (positive or negative)
    ---@param value_type KVItemType
    ---@param set_by_id number
    ---@param set_by_host string
    ---@param default? number default value before increment if entry does not exist, leave nil to return error
    ---@return KVItem? entry updated entry or nil for error
    ---@return string? error error if entry is nil
    local function increment_entry(key, value, value_type, set_by_id, set_by_host, default)
        if value_type ~= KVItemType.NUMBER then
            log:trace('Value type', value_type, 'is not', KVItemType.NUMBER)
            return nil, 'increment must be on type number not ' .. value_type
        end
        if default ~= nil and type(default) ~= 'number' then
            log:trace('Default value', default, 'is not a number')
            return nil, 'Default value must be a number for increment operation'
        end

        log:debug('Increment', key, 'by value', value, 'from', set_by_id, set_by_host)

        -- TODO does this need a lock?
        local entry = read_entry(key)

        if entry == nil then
            if default == nil then
                log:trace('Entry is nil for key', key)
                return nil, 'Missing entry'
            else
                log:trace('Entry is nil for key', key, 'creating new')
                local success, err = update_entry(key, default + value, KVItemType.NUMBER, set_by_id, set_by_host)
                log:trace('Update key', key, 'resulted in', success, err)
                if not success then
                    return nil, err
                end
            end
        else
            log:trace('Entry exists for', key)
            if entry.value_type ~= KVItemType.NUMBER then
                log:trace('Entry for key', key, 'is not a number, got', entry.value_type)
                return nil, 'Stored value is not a number, cannot increment'
            end

            local success, err = update_entry(key, entry.value + value, KVItemType.NUMBER, set_by_id, set_by_host)
            log:trace('Update key', key, 'resulted in', success, err)
            if not success then
                return nil, err
            end
        end

        return entry
    end

    server:route(
        'set',
        {
            request_model = Schema:new({
                entry = {
                    type = FieldType.OBJECT,
                    object = {
                        key = { type = FieldType.STRING },
                        value = ValueUnionField,
                        value_type = { type = FieldType.STRING },
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
            local success, err = update_entry(
                entry.key,
                entry.value,
                entry.value_type or KVItemType.STRING,
                entry.set_by_id,
                entry.set_by_host
            )
            if not success then
                return request:err_response(err)
            end
            return request:ok_response()
        end
    )

    server:route(
        'increment',
        {
            request_model = Schema:new({
                entry = {
                    type = FieldType.OBJECT,
                    object = {
                        key = { type = FieldType.STRING },
                        value = {
                            type = FieldType.UNION,
                            types = {
                                { type = FieldType.INTEGER },
                                { type = FieldType.FLOAT },
                            },
                        },
                        value_type = { type = FieldType.STRING },
                        value_default = {
                            type = FieldType.UNION,
                            optional = true,
                            types = {
                                { type = FieldType.INTEGER },
                                { type = FieldType.FLOAT },
                            },
                        },
                        set_by_host = { type = FieldType.STRING },
                        set_by_id = { type = FieldType.INTEGER },
                    },
                },
            }),
            response_model = Schema:new({
                entry = {
                    type = FieldType.OBJECT,
                    object = {
                        key = { type = FieldType.STRING },
                        value = {
                            type = FieldType.UNION,
                            types = {
                                { type = FieldType.INTEGER },
                                { type = FieldType.FLOAT },
                            },
                        },
                        value_type = { type = FieldType.STRING },
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
            local entry = body.entry
            local new_entry, err = increment_entry(
                entry.key,
                entry.value,
                entry.value_type,
                entry.set_by_id,
                entry.set_by_host,
                entry.value_default
            )
            if new_entry == nil then
                return request:err_response(err)
            end
            return request:ok_response({ entry = new_entry })
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
                        value = ValueUnionField,
                        value_type = { type = FieldType.STRING },
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
                    value_type = entry.value_type,
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
                        value = ValueUnionField,
                        value_type = { type = FieldType.STRING },
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
                            value = ValueUnionField,
                            value_type = { type = FieldType.STRING, optional = true },
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
                    value_type = entry.value_type,
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
