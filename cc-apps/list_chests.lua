-- Remember to update README.md with any changes here
-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    -- TODO update log file path
    filepath = 'logs/list_chest.log',
}
local log = logging.get_logger('main')

local table_size = require 'cc-libs.util.table_size'

local INTERFACE = 'minecraft:barrel_11'

local function main()
    local modem = assert(peripheral.find('modem'))
    log:info('Modem is', modem.getNameLocal())
    ---@cast modem ccTweaked.peripherals.WiredModem

    local r_names = modem.getNamesRemote()
    log:debug('Has remote names', table.concat(r_names, ', '))

    ---@type ccTweaked.peripherals.Inventory
    local inv

    local all_items_count = 0

    for _, name in ipairs(r_names) do
        local types = { modem.getTypeRemote(name) }
        log:debug('Remote', name, 'is type', table.concat(types, ', '))
        if modem.hasTypeRemote(name, 'inventory') then
            ---@type ccTweaked.peripherals.inventory.itemList
            local items = modem.callRemote(name, 'list')
            local size = table_size(items)
            if size > 0 then
                log:info(name, 'is inventory with', table_size(items), 'items')
                log:debug(name, items)
                for slot, item in pairs(items) do
                    all_items_count = all_items_count + item.count
                    log:debug('Moving', item.count, 'items from slot', slot, 'to', INTERFACE)
                    modem.callRemote(name, 'pushItems', INTERFACE, slot)
                end
            end
        end
    end

    log:info('There are', all_items_count, 'items in the system')
end

log:catch_errors(main)
