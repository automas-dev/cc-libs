-- Setup import paths
package.path = '../../?.lua;../../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/server_inventory.log',
}
local log = logging.get_logger('main')

local ccl_schemas = require 'cc-libs.net.proto.schema'
local Schema = ccl_schemas.Schema
local FieldType = ccl_schemas.FieldType

local json = require 'cc-libs.util.json'

local table_size = require 'cc-libs.util.table_size'

local INTERFACE = 'minecraft:barrel_13'

---This is a copy of peripheral.wrap that wraps a remote peripheral.
---@param modem ccTweaked.peripherals.WiredModem
---@param name string
---@return ccTweaked.peripherals.Inventory|nil
---@see peripheral.wrap
local function wrap_remote_inv(modem, name)
    local methods = modem.getMethodsRemote(name)
    if not methods then
        return nil
    end

    -- We store our types array as a list (for getType) and a lookup table (for hasType).
    local types = { modem.getTypeRemote(name) }
    for i = 1, #types do
        types[types[i]] = true
    end
    local result = setmetatable({}, {
        __name = 'peripheral',
        name = name,
        type = types[1],
        types = types,
    })
    for _, method in ipairs(methods) do
        result[method] = function(...)
            return modem.callRemote(name, method, ...)
        end
    end
    return result
end

---@type SchemaField
local ItemGroupField = {
    type = FieldType.OBJECT,
    object = {
        id = { type = FieldType.STRING },
        displayName = { type = FieldType.STRING },
    },
}

local ItemSchema = Schema:new({
    name = { type = FieldType.STRING },
    displayName = { type = FieldType.STRING },
    count = { type = FieldType.INTEGER },
    maxCount = { type = FieldType.INTEGER },
    tags = {
        type = FieldType.OBJECT,
        key = { type = FieldType.STRING },
        value = { type = FieldType.BOOL },
    },
    itemGroups = {
        type = FieldType.ARRAY,
        value = ItemGroupField,
    },
    mapColor = { type = FieldType.INTEGER },
    -- This one is returned by getItemDetail but it's optional to validate objects we make
    mapColour = { type = FieldType.INTEGER, optional = true },
    nbt = { type = FieldType.STRING, optional = true },
})

---@alias SlotId integer

---@enum ChestUse
local ChestUse = {
    Storage = 'STORAGE',
    Interface = 'INTERFACE',
}

---@class ChestItemGroup
---@field id string
---@field displayName string

---@class ChestItem
---@field name string
---@field displayName string
---@field count integer
---@field maxCount integer
---@field tags { [string]: true }
---@field itemGroups { [string]: ChestItemGroup[] }
---@field mapColor integer
---@field nbt string?

---@class ChestInventory
---@field name string
---@field use ChestUse
---@field size integer
---@field items { [SlotId] : ChestItem }

---Scan all inventories attached to the network
---@param modem ccTweaked.peripherals.WiredModem
---@param saved_inv? { capacity: integer, used: integer, inventory: { [string]: ChestInventory } }
---@return { capacity: integer, used: integer, inventory: { [string]: ChestInventory } } chests
---@return ChestInventory? interfaces
---@see ccTweaked.peripherals.Inventory
local function build_inventory(modem, saved_inv)
    log:info('Building inventory')

    local names = modem.getNamesRemote()
    log:debug('Has remote names', table.concat(names, ', '))

    local capacity = 0
    ---@type { [string]: ChestInventory }
    local inventory = {}
    local inventory_count = 0
    local used_count = 0

    local interface_inv = nil

    for _, name in ipairs(names) do
        if modem.hasTypeRemote(name, 'inventory') then
            log:trace('Inspecting remote inventory', name)
            local inv = assert(wrap_remote_inv(modem, name))
            local size = inv.size()
            capacity = capacity + size
            inventory_count = inventory_count + 1

            local items = {}
            -- IMPORTANT each call to inv.list() takes 1 tick (50 ms)
            for slot, item in pairs(inv.list()) do
                -- Try to find item in existing inventory data
                local saved_item = nil
                if saved_inv then
                    saved_item = saved_inv.inventory[name].items[slot]
                end

                -- Get item details from getItemDetail if it does not already exist
                local detail = nil
                if saved_item and item.name == saved_item.name and item.count == saved_item.count then
                    log:trace('Using saved item data for', name, slot)
                    detail = saved_item
                else
                    -- TODO create a validation function that always uses getItemDetail
                    log:trace('Calling getItemDetail for', name, slot)
                    -- IMPORTANT each call to inv.getItemDetail() takes 1 tick (50 ms)
                    detail = inv.getItemDetail(slot)
                    log:trace('detail', detail)
                end

                -- Because getITemDetail fields are undocumented, check that our assumed schema is correct
                local valid, error_path, err = ItemSchema:validate(detail, false)
                if not valid then
                    error(name .. ' ' .. slot .. ' ' .. error_path .. ' ' .. err)
                end

                log:trace('item validation passed')

                items[slot] = detail
                used_count = used_count + 1
            end

            log:debug('Remote inventory', name, 'has capacity', size, 'and', table_size(items), 'items')

            inventory[name] = {
                name = name,
                use = name == INTERFACE and ChestUse.Interface or ChestUse.Storage,
                size = size,
                items = items,
            }

            if inventory[name].use == ChestUse.Interface then
                if interface_inv then
                    log:error('Found multiple interface inventories')
                end
                interface_inv = inventory[name]
            end
        else
            log:trace('Skipping non inventory remote', name)
        end
    end

    log:debug('Inventory has capacity', capacity, 'across', inventory_count, 'inventories')

    return {
        capacity = capacity,
        used = used_count,
        inventory = inventory,
    }, interface_inv
end

local function dump_inv(inv)
    local file = assert(io.open('inventory.json', 'w'))
    file:write(json.encode(inv))
    file:close()
end

local function load_inv()
    local file = assert(io.open('inventory.json', 'r'))
    local inv = json.decode(file:read('a'))
    file:close()
    return inv
end

---@param inventory { [string]: ChestInventory }
---@return string? name
---@return integer? slot
local function find_empty_slot(inventory)
    assert(inventory ~= nil)
    for name, inv in pairs(inventory) do
        for slot = 1, inv.size do
            if not inv[slot] then
                return inv.name, slot
            end
        end
    end
end

local function main()
    local modem = assert(peripheral.find('modem'), 'No modem connected')
    ---@cast modem ccTweaked.peripherals.WiredModem

    log:info('Modem name is', modem.getNameLocal() or 'nil')

    local success, saved_inv = pcall(load_inv)
    if not success then
        -- Rename for clarity
        local err = saved_inv
        log:warning('Failed to load saved inventory', err)
        saved_inv = nil
    else
        assert(saved_inv.inventory, 'Load inventory is missing field inventory')
    end

    local inv, interface_inv = build_inventory(modem, saved_inv)
    local used_perc = inv.used / inv.capacity * 100
    log:info(
        'Storage has capacity of',
        inv.capacity,
        'slots with',
        inv.used,
        'slots in use (',
        math.floor(used_perc * 100) / 100,
        '% )'
    )

    if interface_inv then
        log:info('Watching interface inventory')
        local r_inv = assert(wrap_remote_inv(modem, interface_inv.name))

        while true do
            log:trace('Checking interface inventory')

            local r_items = r_inv.list()
            if #r_items > 0 then
                log:info('Moving items from input into storage')

                for slot, item in pairs(r_items) do
                    log:debug('Moving item', item, 'from slot', slot)
                    local details = r_inv.getItemDetail(slot)

                    -- target_slot is not needed
                    local target_name, target_slot = find_empty_slot(inv.inventory)
                    if target_name and target_slot then
                        log:info('Moving', item.name, slot, 'to', target_name)

                        local moved = r_inv.pushItems(target_name, slot)
                        log:trace('Moved', moved, 'items')

                        -- TODO handle partial stacks being combined
                        assert(moved == item.count, 'Not enough items moved, ' .. moved .. ' of ' .. item.count)
                        inv.inventory[target_name].items[target_slot] = details
                    end
                end

                -- TODO handle interior empty slots
                dump_inv(inv)
            end

            sleep(10)
        end
    else
        log:warning('Could not find interface inventory', INTERFACE)
    end
end

log:catch_errors(main)
