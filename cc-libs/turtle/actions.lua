local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('actions')

local M = {}

function M.find_slot(item_name, need)
    need = need or 1

    local torch_slot = 0
    for i = 1, 16 do
        if turtle.getItemDetail(i).name == item_name then
            torch_slot = i
        end
    end

    if torch_slot == 0 then
        log:info('Item', item_name, 'was not found in inventory')
    elseif turtle.getItemCount(torch_slot) < need then
        log:info('Not enough of', item_name, 'found in inventory')
        torch_slot = 0
    end

    return torch_slot
end

function M.find_torch(need)
    return M.find_slot('minecraft:torch', need)
end

function M.assert_fuel(need)
    log:info('Starting fuel level', turtle.getFuelLevel())
    log:debug('Fuel needed is', need)
    if turtle.getFuelLevel() < need then
        log:fatal('Not enough fuel! Need', need)
    end
end

function M.inventory_full()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end
    return true
end

function M.dump_slot(slot)
    turtle.select(slot)
    while turtle.getItemCount() > 0 do
        turtle.drop()
    end
end

function M.place_torch()
    log:debug('Place torch')

    local old_slot = turtle.getSelectedSlot()

    local torch_slot = M.find_torch(1)
    if torch_slot == 0 then
        log:error('No torches were found in inventory')
        return false
    end

    turtle.select(torch_slot)
    turtle.placeDown()
    turtle.select(old_slot)

    return true
end

return M
