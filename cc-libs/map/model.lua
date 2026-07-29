local table_copy = require 'cc-libs.util.table_copy'

local ccl_schema = require 'cc-libs.net.proto.schema'
local FieldType = ccl_schema.FieldType
local Schema = ccl_schema.Schema

---@type SchemaField
local PositionField = {
    type = FieldType.OBJECT,
    object = {
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local PointField = {
    type = FieldType.OBJECT,
    object = {
        id = { type = FieldType.STRING },
        links = { type = FieldType.OBJECT, key = { type = FieldType.STRING }, value = { type = FieldType.FLOAT } },
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local OptionalPointField = {
    type = FieldType.OBJECT,
    optional = true,
    object = {
        id = { type = FieldType.STRING },
        links = { type = FieldType.OBJECT, key = { type = FieldType.STRING }, value = { type = FieldType.FLOAT } },
        x = { type = FieldType.FLOAT },
        y = { type = FieldType.FLOAT },
        z = { type = FieldType.FLOAT },
    },
}

---@type SchemaField
local LinksField = {
    type = FieldType.OBJECT,
    optional = true,
    key = { type = FieldType.STRING },
    value = { type = FieldType.FLOAT },
}

---@type SchemaField
local MapField = {
    type = FieldType.OBJECT,
    object = {
        graph = {
            type = FieldType.OBJECT,
            key = { type = FieldType.STRING },
            value = PointField,
        },
        waypoints = {
            type = FieldType.OBJECT,
            key = { type = FieldType.STRING },
            value = { type = FieldType.STRING },
        },
    },
}

local NameSchema = Schema:new({
    name = { type = FieldType.STRING },
})

local PIDSchema = Schema:new({
    pid = { type = FieldType.STRING },
})

local WaypointSchema = Schema:new({
    found = { type = FieldType.BOOL },
    waypoint = OptionalPointField,
    name = { type = FieldType.STRING, optional = true },
})

local M = {}

-- get route

M.GetResponseSchema = Schema:new({
    map = MapField,
})

-- add_node route

M.AddNodeRequestSchema = Schema:new({
    pos = PositionField,
    links = LinksField,
})

M.AddNodeResponseSchema = Schema:new({
    action = { type = FieldType.STRING },
    node = PointField,
})

-- batch_update route

M.BatchUpdateRequestSchema = Schema:new({
    nodes = {
        type = FieldType.ARRAY,
        value = PointField,
    },
})

-- remove_node route

M.RemoveNodeRequestSchema = PIDSchema

M.RemoveNodeResponseSchema = Schema:new({
    node = OptionalPointField,
})

-- add_waypoint route

M.AddWaypointRequestSchema = Schema:new({
    name = { type = FieldType.STRING },
    pos = PositionField,
})

M.AddWaypointResponseSchema = Schema:new({
    waypoint = PointField,
    action = { type = FieldType.STRING },
})

-- get_waypoint route

M.GetWaypointRequestSchema = NameSchema

M.GetWaypointResponseSchema = WaypointSchema

-- remove_waypoint route

M.RemoveWaypointRequestSchema = NameSchema

M.RemoveWaypointResponseSchema = WaypointSchema

-- list_waypoints route

M.ListWaypointsResponseSchema = Schema:new({
    waypoints = {
        type = FieldType.ARRAY,
        value = {
            type = FieldType.OBJECT,
            object = {
                name = { type = FieldType.STRING },
                waypoint = PointField,
            },
        },
    },
})

-- mask route

M.MaskRequestSchema = PIDSchema

-- unmask route

M.UnmaskRequestSchema = PIDSchema

return M
