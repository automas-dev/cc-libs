-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/lumber.log',
}
local log = logging.get_logger('main')

local inventory = require 'cc-libs.turtle.inventory'

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local location = Location:new()
local tmc = Motion:new(location)
tmc:enable_dig()

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

local function is_log()
    local exists, info = turtle.inspect()
    if exists then
        local name = info.name
        return string.find(name, 'log') ~= nil
    end
    return false
end

-- TODO inv.pullItems returns success but no items are moved
local function pull_from_inventory()
    log:info('Trying to pull a sapling from the chest below')
    local inv = peripheral.wrap('bottom')
    ---@cast inv ccTweaked.peripherals.Inventory
    for slot = 1, inv.size() do
        local item = inv.getItemDetail(slot)
        log:debug('Chest slot', slot, 'has item', item)
        if item and item.tags['minecraft:saplings'] then
            local count = inv.pullItems('bottom', slot)
            log:info('Got', count, 'saplings from the chest')
        end
    end
    log:warning('No saplings in chest')
end

local function place_sapling()
    local slot = inventory.find_slot_tag('minecraft:saplings')
    if not slot then
        log:info('Getting items from chest bellow')
        -- pull_from_inventory()
        while turtle.suckDown() do
        end
        slot = inventory.find_slot_tag('minecraft:saplings')
    end
    if slot then
        assert(turtle.select(slot))
        assert(turtle.place())
        return true
    else
        log:warning('Failed to find sapling to plant')
    end
    return false
end

local function harvest()
    log:info('Starting harvest')
    if turtle.getFuelLevel() == 0 then
        telem:send_alert('no_fuel', 'Out of fuel')
        error('Out of fuel')
    end
    local height = 0
    while is_log() do
        log:trace('Mining log at height', height)
        turtle.dig()
        tmc:up()
        height = height + 1
    end
    log:info('Finished mining', height, 'logs')
    tmc:down(height)
end

local function main()
    log:info('Starting lumber')
    if not turtle.detectDown() then
        log:info('Returning to floor')
        while not turtle.detectDown() do
            tmc:down()
        end
        log:info('Found floor')
    end
    log:info('Waiting for logs')
    while true do
        if is_log() then
            harvest()
            if not place_sapling() then
                log:info('Did not place a sapling so the program will exit')
                return
            end
        end
        sleep(1)
    end
end

telem:run_parallel_with('main', log:wrap_fn(main))
