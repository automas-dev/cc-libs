local table_copy = require 'cc-libs.util.table_copy'

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

---@type SchemaField
local NumberValueField = {
    type = FieldType.UNION,
    types = {
        { type = FieldType.INTEGER },
        { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local OptionalNumberValueField = table_copy(NumberValueField)
OptionalNumberValueField.optional = true

---@type SchemaField
local ValueField = {
    type = FieldType.UNION,
    types = {
        { type = FieldType.INTEGER },
        { type = FieldType.FLOAT },
        { type = FieldType.STRING },
    },
}

---@type SchemaField
local CreateEntryField = {
    type = FieldType.OBJECT,
    object = {
        key = { type = FieldType.STRING },
        value = ValueField,
        value_type = { type = FieldType.STRING },
        set_by_host = { type = FieldType.STRING },
        set_by_id = { type = FieldType.INTEGER },
    },
}

---@type SchemaField
local EntryField = table_copy(CreateEntryField)
EntryField.object['last_update'] = { type = FieldType.STRING }

---@type SchemaField
local OptionalEntryField = table_copy(EntryField)
OptionalEntryField.optional = true

---@type SchemaField
local CreateNumberEntryField = {
    type = FieldType.OBJECT,
    object = {
        key = { type = FieldType.STRING },
        value = NumberValueField,
        value_default = OptionalNumberValueField,
        value_type = { type = FieldType.STRING },
        set_by_host = { type = FieldType.STRING },
        set_by_id = { type = FieldType.INTEGER },
    },
}

---@type SchemaField
local NumberEntryField = table_copy(CreateNumberEntryField)
NumberEntryField.object['last_update'] = { type = FieldType.STRING }

local KeySchema = Schema:new({
    key = { type = FieldType.STRING },
})

local M = {}

-- set route

M.SetRequestSchema = Schema:new({
    entry = CreateEntryField,
})

-- increment route

M.IncrementRequestSchema = Schema:new({
    entry = CreateNumberEntryField,
})

M.IncrementResponseSchema = Schema:new({
    entry = NumberEntryField,
})

-- get route

M.GetRequestSchema = KeySchema

M.GetResponseSchema = Schema:new({
    found = { type = FieldType.BOOL },
    entry = OptionalEntryField,
})

-- get_history route

M.GetHistoryRequestSchema = KeySchema

M.GetHistoryResponseSchema = Schema:new({
    found = { type = FieldType.BOOL },
    entry = OptionalEntryField,
    history = {
        type = FieldType.ARRAY,
        optional = true,
        value = EntryField,
    },
})
return M
