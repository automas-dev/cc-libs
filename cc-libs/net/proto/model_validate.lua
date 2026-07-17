---@enum FieldType
local FieldType = {
    BOOL = 'bool',
    INTEGER = 'integer',
    FLOAT = 'float',
    STRING = 'string',
    ARRAY = 'array',
    OBJECT = 'object',
}

---@class Field
---@field type FieldType
---@field optional boolean?
---TODO
---@field validate? fun(val: any): boolean
---@field array Field? defines elements of array type
---@field object Schema? defines fields of object type

---@alias Schema { [string]: Field }

---@class Model
---@field schema Schema
local Model = {}

---Create a new Model object and check schema
---@param schema Schema
---@return Model
function Model:new(schema)
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
---@param field Field
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:check_field(field, path)
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
---@param schema Schema
---@param path? string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:check_schema(schema, path)
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

---Coerce a single value into a type
---@param field_type FieldType
---@param value any
---@return boolean
local function coerce_type(field_type, value)
    if field_type == FieldType.BOOL then
        if type(value) == 'string' then
            value = string.lower(value)
            if value == 'true' then
                return true
            elseif value == 'false' then
                return false
            else
                error('Cannot coerce value ' .. value .. ' to boolean')
            end
        elseif type(value) == 'number' then
            return value ~= 0
        else
            error('Cannot coerce type ' .. type(value) .. ' to boolean')
        end
    elseif field_type == FieldType.INTEGER then
        if type(value) == 'string' then
            value = tonumber(value)
            if value == nil then
                error('Cannot coerce value ' .. value .. ' to integer')
            end
        elseif type(value) ~= 'number' then
            error('Cannot coerce type ' .. type(value) .. ' to integer')
        end
        if value % 1 ~= 0 then
            -- TODO this is starting to be validation logic, update bool and this wip integer to be only coercion if possible. Default return unmodified value.
        end
    elseif field_type == FieldType.FLOAT then
        return type(value) == 'number'
    elseif field_type == FieldType.STRING then
        return type(value) == 'string'
    elseif field_type == FieldType.ARRAY then
        return type(value) == 'table' and table_is_array(value)
    elseif field_type == FieldType.OBJECT then
        return type(value) == 'table' and not table_is_array(value)
    else
        error('Unknown field type ' .. field_type)
    end
end

---Validate a single value is of type
---@private
---@param field_type FieldType
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:validate_type(field_type, value, path)
    if field_type == FieldType.BOOL then
        if type(value) ~= 'boolean' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        end
    elseif field_type == FieldType.INTEGER then
        if type(value) ~= 'number' then
            return false, path, 'Invalid type ' .. type(value) .. ' expected ' .. field_type
        elseif value % 1 == 0 then
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
---@param field Field
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:validate_field(field, value, path)
    if not field.optional and value == nil then
        return false, path, 'Missing required field'
    end
    local valid, error_path, error = self:validate_type(field.type, value, path)
    if not valid then
        return valid, error_path, error
    end
    if field.type == FieldType.ARRAY then
        valid, error_path, error = self:validate_array(field.array, value, path)
        if not valid then
            return valid, error_path, error
        end
    elseif field.type == FieldType.OBJECT then
        valid, error_path, error = self:validate_schema(field.object, value, path)
        if not valid then
            return valid, error_path, error
        end
    end
    return true
end

---Validate elements of an array
---@private
---@param arr_field Field
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:validate_array(arr_field, value, path)
    for i, elem in ipairs(value) do
        local valid, error_path, error = self:validate_field(arr_field, elem, path .. '[' .. tostring(i) .. ']')
        if not valid then
            return valid, error_path, error
        end
    end
    return true
end

---Validate data against a schema
---@private
---@param schema Schema
---@param value any
---@param path string
---@return boolean valid
---@return string? error_path
---@return string? error
function Model:validate_schema(schema, value, path)
    for k, field in pairs(schema) do
        elem = value[k]
        if path then
            k = path .. '.' .. k
        end
        if not Model:validate_field(value, field, k) then
            return false
        end
    end
    return true
end

---Validate value against this model
---@param value any
---@return boolean valid
---@return string? error
---@return string? error_path
function Model:validate(value)
    return self:validate_schema(self.schema, value, '')
end

return {
    FieldType = FieldType,
    Model = Model,
}
