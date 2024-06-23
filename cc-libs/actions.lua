local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('actions')

local FORWARD_MAX_TRIES = 10

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

function M.try_forward(n, max_tries)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    max_tries = max_tries or FORWARD_MAX_TRIES
    assert(max_tries >= 0, 'max_tries must be positive')

    for _ = 1, n do
        local did_move = false
        for _ = 1, max_tries do
            if turtle.forward() then
                did_move = true
                break
            else
                log:debug('Could not move forward, trying to dig')
                turtle.dig()
            end
        end

        if not did_move then
            log:fatal('Failed to move forward after', max_tries, 'attempts')
            return false
        end
    end

    return true
end

function M.dig_forward(n, max_tries)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    max_tries = max_tries or FORWARD_MAX_TRIES
    assert(max_tries >= 0, 'max_tries must be positive')

    for _ = 1, n do
        if turtle.getFuelLevel() == 0 then
            log:fatal('Ran out of fuel!')
            return false
        end

        turtle.dig()
        if not M.try_forward(1, max_tries) then
            return false
        end
        turtle.digUp()

        local has_block, data = turtle.inspectDown()
        if has_block then
            if data.name ~= 'minecraft:torch' then
                turtle.digDown()
            end
        end
    end

    return true
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
