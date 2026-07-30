local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('turtle.inventory')

local Inv = {}

---Returns an iterator over the turtle inventory. This iter only returns name
---and count for each slot.
---
---```
---for slot, item in Inv.iter() do
---    if item then
---        print('Slot', slot, 'has', item.count, item.name)
---    end
---end
---```
---
---@return fun(): (integer|nil, ccTweaked.turtle.slotInfo|nil)
function Inv.iter()
    local i = 1
    return function()
        local details = turtle.getItemDetail(i, false)
        while i < 16 and not details do
            i = i + 1
            details = turtle.getItemDetail(i, false)
        end
        if i <= 16 and details then
            local slot = i
            i = i + 1
            ---@cast details ccTweaked.turtle.slotInfo
            return slot, details
        end
    end
end

---Returns an iterator over the turtle inventory. This iter returns detailed
---slot information.
---
---```
---for slot, item in Inv.detailed_iter() do
---    if item then
---        print('Slot', slot, 'has', item.count, item.name)
---        print('Display name', item.displayName)
---        print('Max count', item.maxCount)
---        for tag in pairs(item.tags) do
---            print('Tag', tag)
---        end
---    end
---end
---```
---
---@return fun(): (integer|nil, ccTweaked.turtle.slotInfoDetailed|nil)
function Inv.detailed_iter()
    local i = 1
    return function()
        local details = turtle.getItemDetail(i, true)
        while i < 16 and not details do
            i = i + 1
            details = turtle.getItemDetail(i, true)
        end
        if i <= 16 and details then
            local slot = i
            i = i + 1
            ---@cast details ccTweaked.turtle.slotInfoDetailed
            return slot, details
        end
    end
end

---Find the first slot with the given name.
---@param item_name string minecraft item id
---@return integer|nil slot
function Inv.find_slot_name(item_name)
    log:trace('Finding slot for name', item_name)

    for slot, item in Inv.iter() do
        log:trace('Checking slot', slot, 'found item', item)
        if item.name == item_name then
            log:debug('Item found', item.name, 'has', item.count, 'in slot', slot)
            return slot
        end
    end

    log:debug('No items found with name', item_name)
end

---Find the first slot with on of the given names.
---@param item_names string[] list of minecraft item id
---@return integer|nil slot
function Inv.find_slot_any_name(item_names)
    log:trace('Finding slot with name in', item_names)

    for slot, item in Inv.iter() do
        log:trace('Checking slot', slot, 'found item', item)
        for _, name in ipairs(item_names) do
            if item.name == name then
                log:debug('Item found', item.name, 'has', item.count, 'in slot', slot)
                return slot
            end
        end
    end

    log:debug('No items found with names', item_names)
end

---Find the first slot with a given tag.
---@param tag string minecraft tag id
---@return integer|nil slot
function Inv.find_slot_tag(tag)
    log:trace('Finding slot for tag', tag)

    for slot, item in Inv.detailed_iter() do
        log:trace('Checking slot', slot, 'found item', item)
        if item.tags[tag] then
            log:debug('Item found', item.name, 'for tag', tag, 'has', item.count, 'in slot', slot)
            return slot
        end
    end

    log:debug('No items found with tag', tag)
end

---Count the number of items with the given name.
---@param item_name string minecraft item id
---@return integer count
function Inv.count_name(item_name)
    log:trace('Counting items for name', item_name)

    local count = 0
    for slot, item in Inv.iter() do
        log:trace('Checking slot', slot, 'found item', item)
        if item.name == item_name then
            log:debug('Item found', item.name, 'has', item.count, 'in slot', slot)
            count = count + item.count
        end
    end

    return count
end

---Count the number of items with on of the given names.
---@param item_names string[] list of minecraft item id
---@return integer count
function Inv.count_any_name(item_names)
    log:trace('Counting items with name in', item_names)

    local count = 0
    for slot, item in Inv.iter() do
        log:trace('Checking slot', slot, 'found item', item)
        for _, name in ipairs(item_names) do
            if item.name == name then
                log:debug('Item found', item.name, 'has', item.count, 'in slot', slot)
                count = count + item.count
                break
            end
        end
    end

    return count
end

---Count the number of items with a given tag.
---@param tag string minecraft tag id
---@return integer count
function Inv.count_tag(tag)
    log:trace('Counting items for tag', tag)

    local count = 0
    for slot, item in Inv.detailed_iter() do
        log:trace('Checking slot', slot, 'found item', item)
        if item.tags[tag] then
            log:debug('Item found', item.name, 'for tag', tag, 'has', item.count, 'in slot', slot)
            count = count + item.count
        end
    end

    return count
end

---Check if all slots have at least 1 item
---@return boolean
function Inv.full()
    log:trace('Check if inventory is full')

    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            log:debug('Found free slot', i)
            return false
        else
            log:trace('Slot', i, 'was not free')
        end
    end

    log:debug('Inventory is full')
    return true
end

-- TODO should this one be here?

---Open an inventory peripheral and inspect it's contents. If side is front, top
---or bottom, the block state will be reported with it's contents.
---@param side string peripheral side
---@return {size: integer, slots: table[], details: table, block: table | nil } | nil info inventory details if present
function Inv.examine_inventory(side)
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
        log:debug('Adding block info')
        info.block = block
    end

    return info
end

return Inv
