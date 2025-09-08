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

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        log:trace('Checking slot', i, 'found item', item)
        if item ~= nil and item.name == item_name then
            log:debug('Found item', item.name, 'in slot', i)
            if turtle.getItemCount(i) >= need then
                log:debug('Item found', item_name, 'has', turtle.getItemCount(i), 'in slot', i)
                return i
            end
        end
    end

    log:warning('Item', item_name, 'with', need, 'items was not found in inventory')
    return nil
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

---Check turtle has the needed fuel. Raises error through log:fatal if there is
---not enough fuel.
---@param need number amount of fuel needed
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

---Open an inventory peripheral and inspect it's contents. If side is front, top
---or bottom, the block state will be reported with it's contents.
---@param side string peripheral side
---@return {size: integer, slots: table[], details: table, block: table | nil } | nil info inventory details if present
function M.examine_inventory(side)
    log:debug('Opening peripheral on side', side)

    local is_inv = false
    for _, t in ipairs({ peripheral.getType(side) }) do
        is_inv = is_inv or t == 'inventory'
    end

    if not is_inv then
        log:debug('Peripheral on side', side, 'is not an inventory')
        return nil
    end

    local inv = peripheral.wrap(side)

    if not inv then
        log:debug('No inventory found')
        return nil
    end

    local slots = {}

    for slot in pairs(inv.list()) do
        local detail = inv.getItemDetail(slot)
        log:trace('Slot', k, 'has item', detail.name)
        local limit = inv.getItemLimit(slot)

        slots[slot] = {
            slot = slot,
            detail = detail,
            limit = limit,
        }
    end

    local info = {
        size = inv.size(),
        slots = slots,
    }

    local exists = false
    local block = nil
    if side == 'front' then
        exists, block = turtle.inspect()
    elseif side == 'top' then
        exists, block = turtle.inspectUp()
    elseif side == 'bottom' then
        exists, block = turtle.inspectDown()
    end

    if exists then
        log:debug('Adding block info')
        info.block = block
    end

    return info
end

return M
