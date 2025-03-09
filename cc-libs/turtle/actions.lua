local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('actions')

local M = {}

---Find the first slot with at least `need` items of the given name.
---@param item_name string minecraft item id
---@param need integer 1 to 64
---@return integer|nil
function M.find_slot(item_name, need)
    need = need or 1
    log:debug('Finding slot for', item_name, 'need', need)

    local item_slot = nil
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        log:trace('Checking slot', i, 'found item', item)
        if item ~= nil and item.name == item_name then
            log:debug('Found item', item.name, 'in slot', i)
            item_slot = i
            break
        end
    end

    if item_slot == nil then
        log:warning('Item', item_name, 'was not found in inventory')
    elseif turtle.getItemCount(item_slot) < need then
        log:warning('Not enough of', item_name, 'found in inventory')
        item_slot = nil
    else
        log:debug('Item found', item_name, 'has', turtle.getItemCount(item_slot), 'in slot', item_slot)
    end

    return item_slot
end

---Find the first slot with at least 1 torch.
---@return integer|nil
function M.find_torch()
    return M.find_slot('minecraft:torch', 1)
end

---Find and select the first slot with an item with the given minecraft id
---@param item_name string minecraft item id
---@return integer|nil item_slot slot number if selected
function M.select_slot(item_name)
    log:debug('Select slot for item', item_name)
    local item_slot = M.find_slot(item_name, 1)
    log:debug('Found slot', item_slot)

    if item_slot ~= nil then
        log:debug('Item was selected')
        turtle.select(item_slot)
    else
        log:debug('Did not select item')
    end

    return item_slot
end

function M.assert_fuel(need)
    log:info('Starting fuel level', turtle.getFuelLevel())
    log:debug('Fuel needed is', need)
    if turtle.getFuelLevel() < need then
        log:fatal('Not enough fuel! Need', need)
    end
end

---Check if all slots have at least 1 item
---@return boolean
function M.inventory_full()
    log:debug('Check if inventory is full')
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            log:debug('Found free slot', i)
            log:info('Inventory has space')
            return false
        else
            log:trace('Slot', i, 'was not free')
        end
    end
    log:info('Inventory is full')
    return true
end

---Drop all items from the given slot.
---@param slot integer 1 to 16
---@return integer count number of items dropped
function M.dump_slot(slot)
    assert(slot > 0 and slot <= 16, 'slot must be a number between 1 and 16')
    log:info('Dumping slot', slot)

    turtle.select(slot)

    log:debug('Slot has', turtle.getItemCount(), 'items')

    local count = 0
    while turtle.getItemCount() > 0 do
        log:trace('Dropping item', count)
        turtle.drop()
        count = count + 1
    end
    log:debug('Finished dropping items')
    return count
end

---Select the first slot with at least 1 torch and place it down.
---@return boolean success
function M.place_torch()
    log:info('Place torch')

    local old_slot = turtle.getSelectedSlot()
    log:debug('Storing current slot as', old_slot)

    local torch_slot = M.find_torch()
    if torch_slot == nil then
        log:error('No torches were found in inventory')
        return false
    end
    log:debug('Found torch slot', torch_slot)

    turtle.select(torch_slot)
    log:trace('Selected torch slot', torch_slot)
    turtle.placeDown()
    log:trace('Placed torch')
    turtle.select(old_slot)
    log:trace('Selected old slot', old_slot)

    return true
end

return M
