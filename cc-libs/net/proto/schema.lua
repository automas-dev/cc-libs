local table_size = require 'cc-libs.util.table_size'

---@enum FieldType
local FieldType = {
    BOOL = 'bool',
    INTEGER = 'integer',
    FLOAT = 'float',
    STRING = 'string',
    ARRAY = 'array',
    OBJECT = 'object',
    UNION = 'union',
    ANY = 'any',
}

---@class SchemaField
---@field type FieldType
---@field optional boolean?
---TODO use this
---@field validate? fun(val: any): boolean
---@field value SchemaField? defines elements of array type or object (if `object` is nil)
---@field key SchemaField? defines keys of object type (if `object` is nil)
---@field object SchemaObject? defines structure of object type
---@field types SchemaField[]? defines list of type options for union

---@alias SchemaObject { [string]: SchemaField }

---@class Schema
---@field schema SchemaObject
local Schema = {}

---Create a new Model object and check schema
---@param schema SchemaObject
---@return Schema
function Schema:new(schema)
    local o = {
        schema = schema,
    }
    setmetatable(o, self)
    self.__index = self
    local valid, error_path, err = o:check_schema(schema)
    if not valid then
        error('Schema error ' .. error_path .. ' ' .. err)
    end
    return o
end

---Check a single field object is valid
---@private
---@param field SchemaField
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:check_field(field, path)
    if field.type == nil then
        return false, path, 'Type is nil'
    end
    local type_found = false
    for _, v in pairs(FieldType) do
        if field.type == v then
            type_found = true
            break
        end
    end
    if not type_found then
        return false, path, 'Unknown type ' .. tostring(field.type)
    end
    if field.optional ~= nil and type(field.optional) ~= 'boolean' then
        return false, path, 'Unknown value for optional ' .. tostring(field.optional)
    end
    if field.validate ~= nil and type(field.validate) ~= 'function' then
        return false, path, 'validate is not a function'
    end
    if field.type == FieldType.ARRAY then
        if field.value ~= nil then
            local valid, error_path, error = self:check_field(field.value, path .. '[]')
            if not valid then
                return valid, error_path, error
            end
        end
    else
        if field.value ~= nil and field.type ~= FieldType.OBJECT then
            return false, path, 'value is defined for non array type ' .. field.type
        end
    end
    if field.type == FieldType.OBJECT then
        if field.object ~= nil then
            if field.key ~= nil or field.value ~= nil then
                return false, path, 'Object type cannot have key or value fields if object is not nil'
            end
            local valid, error_path, error = self:check_schema(field.object, path)
            if not valid then
                return valid, error_path, error
            end
        else
            if field.key ~= nil then
                local valid, error_path, error = self:check_field(field.key, path .. '.<key>')
                if not valid then
                    return valid, error_path, error
                end
            end
            if field.value ~= nil then
                local valid, error_path, error = self:check_field(field.value, path .. '.<value>')
                if not valid then
                    return valid, error_path, error
                end
            end
        end
    else
        if field.object ~= nil then
            return false, path, 'object is defined for non object type ' .. field.type
        end
        if field.key ~= nil then
            return false, path, 'key is defined for non object type ' .. field.type
        end
        if field.key ~= nil and field.type ~= FieldType.ARRAY then
            return false, path, 'key is defined for non object type ' .. field.type
        end
    end
    if field.type == FieldType.UNION then
        if field.types == nil then
            return false, path, 'UNION type must have types field'
        elseif #field.types == 0 then
            return false, path, 'UNION type must have at least one type'
        end
        for _, union_type in ipairs(field.types) do
            local valid, error_path, error = self:check_field(union_type, path .. '.<union>')
            if not valid then
                return valid, error_path, error
            end
        end
    else
        if field.types ~= nil then
            return false, path, 'types are defined for non union type ' .. field.type
        end
    end
    return true
end

---Check all fields of a schema
---@private
---@param schema SchemaObject
---@param path? string
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:check_schema(schema, path)
    for k, field in pairs(schema) do
        if path then
            k = path .. '.' .. k
        end
        local valid, error_path, error = self:check_field(field, k)
        if not valid then
            return valid, error_path, error
        end
    end
    return true
end

---Check if table is an array
---@param t table
---@return boolean
local function table_is_array(t)
    local keys = {}
    for k, _ in pairs(t) do
        if type(k) ~= 'number' then
            return false
        end
        table.insert(keys, k)
    end
    table.sort(keys)
    for i, k in ipairs(keys) do
        if k ~= i then
            return false
        end
    end
    return true
end

---Validate a single value is of type
---@private
---@param field SchemaField
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_type(field, value, path)
    if field.type == FieldType.BOOL then
        if type(value) ~= 'boolean' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        end
    elseif field.type == FieldType.INTEGER then
        if type(value) ~= 'number' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        elseif value % 1 ~= 0 then
            return false, path, 'Invalid type float expected ' .. field.type
        end
    elseif field.type == FieldType.FLOAT then
        if type(value) ~= 'number' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        end
    elseif field.type == FieldType.STRING then
        if type(value) ~= 'string' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        end
    elseif field.type == FieldType.ARRAY then
        if type(value) ~= 'table' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        elseif table_size(value) > 0 and not table_is_array(value) then
            return false, path, 'Invalid type object expected ' .. field.type
        end
    elseif field.type == FieldType.OBJECT then
        if type(value) ~= 'table' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field.type
        elseif table_size(value) > 0 and table_is_array(value) then
            return false, path, 'Invalid type array expected ' .. field.type
        end
    end
    return true
end

---Validate a value against it's field
---This is being defined in validate_schema so it can call validate_schema
---@private
---@param field SchemaField
---@param value any
---@param path string
---@param allow_extra boolean
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_field(field, value, path, allow_extra)
    if field.optional and value == nil then
        return true
    end
    if not field.optional and value == nil then
        return false, path, 'Missing required field'
    end
    local valid, error_path, error = self:validate_type(field, value, path)
    if not valid then
        return valid, error_path, error
    end
    if field.type == FieldType.ARRAY then
        if field.value ~= nil then
            valid, error_path, error = self:validate_array(field.value, value, path, allow_extra)
            if not valid then
                return valid, error_path, error
            end
        end
    elseif field.type == FieldType.OBJECT then
        if field.object ~= nil then
            valid, error_path, error = self:validate_object(field.object, value, path, allow_extra)
            if not valid then
                return valid, error_path, error
            end
        else
            if field.key ~= nil or field.value ~= nil then
                valid, error_path, error =
                    self:validate_object_key_value(field.key, field.value, value, path, allow_extra)
                if not valid then
                    return valid, error_path, error
                end
            end
        end
    elseif field.type == FieldType.UNION then
        local types_no_match = {}
        for _, union_type in ipairs(field.types) do
            valid = self:validate_field(union_type, value, path, allow_extra)
            if valid then
                return true
            end
            table.insert(types_no_match, union_type.type)
        end
        return false, path, 'No type matched from union types ' .. table.concat(types_no_match, ', ')
    end
    return true
end

---Validate elements of an array
---@private
---@param arr_field SchemaField
---@param value any
---@param path string
---@param allow_extra boolean
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_array(arr_field, value, path, allow_extra)
    assert(arr_field ~= nil)
    for i, elem in ipairs(value) do
        local valid, error_path, error =
            self:validate_field(arr_field, elem, path .. '[' .. tostring(i) .. ']', allow_extra)
        if not valid then
            return valid, error_path, error
        end
    end
    return true
end

---Validate data against a schema
---@private
---@param key_type SchemaField?
---@param value_type SchemaField?
---@param value any
---@param path string
---@param allow_extra boolean
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_object_key_value(key_type, value_type, value, path, allow_extra)
    if type(value) ~= 'table' then
        return false, path, 'Value is not table'
    end
    for k, elem in pairs(value) do
        if key_type ~= nil then
            local valid, error_type, error = self:validate_field(key_type, k, path .. '.<key>' .. k, allow_extra)
            if not valid then
                return valid, error_type, error
            end
        end
        if value_type ~= nil then
            local valid, error_type, error = self:validate_field(value_type, elem, path .. '.' .. k, allow_extra)
            if not valid then
                return valid, error_type, error
            end
        end
    end
    return true
end

---Validate data against a schema
---@private
---@param schema SchemaObject
---@param value any
---@param path string
---@param allow_extra boolean
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_object(schema, value, path, allow_extra)
    if type(value) ~= 'table' then
        return false, path, 'Value is not table'
    end
    if not allow_extra then
        for k, _ in pairs(value) do
            if schema[k] == nil then
                if path ~= nil and path ~= '' then
                    k = path .. '.' .. k
                end
                return false, k, 'Unexpected field'
            end
        end
    end
    for k, field in pairs(schema) do
        elem = value[k]
        if path ~= nil and path ~= '' then
            k = path .. '.' .. k
        end
        local valid, error_type, error = self:validate_field(field, elem, k, allow_extra)
        if not valid then
            return valid, error_type, error
        end
    end
    return true
end

---Validate value against this model
---@param value any
---@param allow_extra? boolean extra keys are ignored, defaults to true
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate(value, allow_extra)
    if allow_extra == nil then
        allow_extra = true
    end
    return self:validate_object(self.schema, value, '', allow_extra)
end

return {
    FieldType = FieldType,
    Schema = Schema,
}
