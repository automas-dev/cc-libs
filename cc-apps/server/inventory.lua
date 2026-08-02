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

local json = require 'cc-libs.util.json'

local table_size = require 'cc-libs.util.table_size'

local INTERFACE = 'minecraft:barrel_11'

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

---@class InventoryEntry
---@field name string
-- ---@field inv ccTweaked.peripherals.Inventory
---@field items ccTweaked.peripherals.inventory.itemList
---@field is_interface boolean?

---@class Inventory
---@field capacity integer
---@field used integer
---@field inventory { [string]: InventoryEntry }

---Scan all inventories attached to the network
---@param modem ccTweaked.peripherals.WiredModem
---@return Inventory
---@see ccTweaked.peripherals.Inventory
local function build_inventory(modem)
    log:info('Building inventory')

    local names = modem.getNamesRemote()
    log:debug('Has remote names', table.concat(names, ', '))

    local capacity = 0
    ---@type { [string]: InventoryEntry }
    local inventories = {}
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
            for slot in pairs(inv.list()) do
                local detail = inv.getItemDetail(slot)
                log:trace('detail', detail)
                items[slot] = detail
                used_count = used_count + 1
            end

            log:debug('Remote inventory', name, 'has capacity', size, 'and', table_size(items), 'items')

            inventories[name] = {
                name = name,
                -- inv = inv,
                items = items,
                is_interface = name == INTERFACE,
            }

            if inventories[name].is_interface then
                if interface_inv then
                    log:error('Found multiple interface inventories')
                end
                interface_inv = inventories[name]
            end
        else
            log:trace('Skipping non inventory remote', name)
        end
    end

    log:debug('Inventory has capacity', capacity, 'across', inventory_count, 'inventories')

    return {
        capacity = capacity,
        used = used_count,
        inventories = inventories,
    }
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

local function main()
    local modem = assert(peripheral.find('modem'), 'No modem connected')
    ---@cast modem ccTweaked.peripherals.WiredModem

    log:info('Modem name is', modem.getNameLocal() or 'nil')

    local inv = build_inventory(modem)
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

    local _, saved_inv = pcall(load_inv)

    if saved_inv then
        -- TODO compare to inv
        if inv.capacity ~= saved_inv.capacity then
            log:warning('Changes have been made, capacity does not match')
        end
    end

    dump_inv(inv)
end

log:catch_errors(main)
