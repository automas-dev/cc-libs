local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('actions')

local ccl_turtle_inv = require 'cc-libs.turtle.inventory'

local M = {}

---Find the first slot with at least `need` items of the given name.
---@deprecated use turtle.inventory.find_slot_name instead
---@param item_name string minecraft item id
---@param need? integer 1 to 64, default 1
---@return integer|nil
function M.find_slot(item_name, need)
    log:warning('Call to deprecated function find_slot, use turtle.inventory.find_slot_name instead')
    need = need or 1
    log:debug('Finding slot for name', item_name, 'need', need)

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        log:trace('Checking slot', i, 'found item', item)
        if item ~= nil and item.name == item_name then
            log:trace('Found item', item.name, 'in slot', i)
            if turtle.getItemCount(i) >= need then
                log:trace('Item found', item_name, 'has', turtle.getItemCount(i), 'in slot', i)
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
    return ccl_turtle_inv.find_slot_name('minecraft:torch')
end

---Find and select the first slot with an item with the given minecraft id
---@param item_name string minecraft item id
---@return integer|nil item_slot slot number if selected
function M.select_slot(item_name)
    log:debug('Select slot for item', item_name)
    local item_slot = ccl_turtle_inv.find_slot_name(item_name)
    log:trace('Found slot', item_slot)

    if item_slot ~= nil then
        log:trace('Item was selected')
        turtle.select(item_slot)
    else
        log:trace('Did not select item')
    end

    return item_slot
end

---Check turtle has the needed fuel. Raises error if there is
---not enough fuel.
---@param need number amount of fuel needed
function M.assert_fuel(need)
    log:info('Starting fuel level', turtle.getFuelLevel())
    log:debug('Fuel needed is', need)
    if turtle.getFuelLevel() < need then
        error('Not enough fuel! Need ' .. tostring(need))
    end
end

---Check turtle has enough items. Raises error if there are
---not enough items.
---@param item_name string minecraft item id
---@param need number amount of fuel needed
function M.assert_items(item_name, need)
    log:debug('Finding count of item', item_name, 'needing', need)

    local has = 0

    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        log:trace('Checking slot', i, 'found item', item)
        if item ~= nil and item.name == item_name then
            log:trace('Found item', item.name, 'in slot', i)
            has = has + turtle.getItemCount(i)
            if has >= need then
                log:trace('Inventory has enough of', item_name)
                return
            end
        end
    end

    error(
        'Inventory does not have enough '
            .. tostring(item_name)
            .. ' found '
            .. tostring(has)
            .. ' need '
            .. tostring(need)
    )
end

---Check if all slots have at least 1 item
---@deprecated use turtle.inventory.inventory_full
---@return boolean
function M.inventory_full()
    log:warning('Call to deprecated function inventory_full, use turtle.inventory.full instead')
    log:debug('Check if inventory is full')
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            log:trace('Found free slot', i)
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
---@param direction string|nil face to dorp, forward, up or down
---@return integer count number of items dropped
function M.dump_slot(slot, direction)
    assert(slot > 0 and slot <= 16, 'slot must be a number between 1 and 16')
    log:trace('Dumping slot', slot)

    turtle.select(slot)

    log:trace('Slot has', turtle.getItemCount(), 'items')

    local count = 0
    while turtle.getItemCount() > 0 do
        log:trace('Dropping item', count)
        if direction == 'up' then
            turtle.dropUp()
        elseif direction == 'down' then
            turtle.dropDown()
        else
            turtle.drop()
        end
        count = count + 1
    end

    log:trace('Finished dropping items')
    return count
end

---Select the first slot with at least 1 torch and place it down.
---@return boolean success
function M.place_torch()
    log:info('Place torch')

    local old_slot = turtle.getSelectedSlot()
    log:trace('Storing current slot as', old_slot)

    local torch_slot = ccl_turtle_inv.find_slot_name('minecraft_torch')
    if torch_slot == nil then
        log:error('No torches were found in inventory')
        return false
    end
    log:trace('Found torch slot', torch_slot)

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
    log:trace('Opening peripheral on side', side)

    local is_inv = false
    for _, t in ipairs({ peripheral.getType(side) }) do
        is_inv = is_inv or t == 'inventory'
    end

    if not is_inv then
        log:trace('Peripheral on side', side, 'is not an inventory')
        return nil
    end

    local inv = peripheral.wrap(side)

    if not inv then
        log:trace('No inventory found')
        return nil
    end

    local slots = {}

    for slot in pairs(inv.list()) do
        local detail = inv.getItemDetail(slot)
        if detail ~= nil then
            log:trace('Slot', slot, 'has item', detail.name)
        else
            log:trace('Slot', slot, 'has no item')
        end
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
        log:trace('Adding block info')
        info.block = block
    end

    return info
end

return M
