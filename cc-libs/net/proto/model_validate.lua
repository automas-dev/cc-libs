---@enum FieldType
local FieldType = {
    BOOL = 'bool',
    INTEGER = 'integer',
    FLOAT = 'float',
    STRING = 'string',
    ARRAY = 'array',
    OBJECT = 'object',
}

---@class SchemaField
---@field type FieldType
---@field optional boolean?
---TODO
---@field validate? fun(val: any): boolean
---@field array SchemaField? defines elements of array type
---@field object SchemaObject? defines fields of object type

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
        if field.array ~= nil then
            local valid, error_path, error = self:check_field(field.array, path .. '[]')
            if not valid then
                return valid, error_path, error
            end
        end
    else
        if field.array ~= nil then
            return false, path, 'array is defined for non array type ' .. field.type
        end
    end
    if field.type == FieldType.OBJECT then
        if field.object ~= nil then
            local valid, error_path, error = self:check_schema(field.object, path)
            if not valid then
                return valid, error_path, error
            end
        end
    else
        if field.object ~= nil then
            return false, path, 'array is defined for non array type ' .. field.type
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
---@param field_type FieldType
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Schema:validate_type(field_type, value, path)
    if field_type == FieldType.BOOL then
        if type(value) ~= 'boolean' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        end
    elseif field_type == FieldType.INTEGER then
        if type(value) ~= 'number' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        elseif value % 1 ~= 0 then
            return false, path, 'Invalid type float expected ' .. field_type
        end
    elseif field_type == FieldType.FLOAT then
        if type(value) ~= 'number' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        end
    elseif field_type == FieldType.STRING then
        if type(value) ~= 'string' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        end
    elseif field_type == FieldType.ARRAY then
        if type(value) ~= 'table' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        elseif not table_is_array(value) then
            return false, path, 'Invalid type object expected ' .. field_type
        end
    elseif field_type == FieldType.OBJECT then
        if type(value) ~= 'table' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        elseif table_is_array(value) then
            return false, path, 'Invalid type array expected ' .. field_type
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
    local valid, error_path, error = self:validate_type(field.type, value, path)
    if not valid then
        return valid, error_path, error
    end
    if field.type == FieldType.ARRAY then
        if field.array ~= nil then
            valid, error_path, error = self:validate_array(field.array, value, path, allow_extra)
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
        end
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
