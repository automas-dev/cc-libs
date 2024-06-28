---@meta ccl_actions

local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('actions')

local M = {}

---Find the first slot with at least `need` items of the given name.
---@param item_name string minecraft item id
---@param need integer 1 to 64
---@return integer|nil
function M.find_slot(item_name, need)
    need = need or 1

    local item_slot = nil
    for i = 1, 16 do
        if turtle.getItemDetail(i).name == item_name then
            item_slot = i
        end
    end

    if item_slot == nil then
        log:info('Item', item_name, 'was not found in inventory')
    elseif turtle.getItemCount(item_slot) < need then
        log:info('Not enough of', item_name, 'found in inventory')
        item_slot = nil
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
    local item_slot = M.find_slot(item_name, 1)

    if item_slot == nil then
        log:warning('Item', item_name, 'was not found in inventory')
        return nil
    end

    turtle.select(item_slot)

    return item_slot
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
