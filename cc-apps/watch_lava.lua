-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/watch_lava.log',
}
local log = logging.get_logger('main')

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local actions = require 'cc-libs.turtle.actions'

local telem = get_telemetry()

---@type ccTweaked.peripherals.Inventory
local chest

local function cauldron_has_lava()
    local exists, data = turtle.inspect()
    return exists and data.name == 'minecraft:lava_cauldron'
end

local function take_lava()
    log:info('Taking lava from cauldron')

    -- Find an empty bucket
    if not actions.select_slot('minecraft:bucket') then
        telem:send_alert('out_of_buckets', 'Turtle has no more empty buckets')
        log:fatal('No more buckets')
    end

    -- Pickup lava with empty bucket
    if not turtle.place() then
        telem:send_alert('lava_missing', 'Turtle failed to pickup lava')
        log:fatal('Failed to extract lava')
    end

    log:trace('Got lava bucket')

    -- Put lava bucket in chest bellow turtle
    if not actions.select_slot('minecraft:lava_bucket') then
        telem:send_alert('lava_missing', 'Turtle failed to find lava bucket in inventory')
        log:fatal('Failed to select lava bucket')
    else
        if not turtle.dropDown() then
            telem:send_alert('cannot_store_lava', 'Failed to store lava bucket in an inventory bellow the turtle')
            log:fatal('Failed to put lava bucket in inventory')
        end
        log:debug('Pushed lava bucket into chest bellow')
    end
end

---Count how many buckets of lava are in the chest
---@return integer
local function count_buckets()
    local count = 0
    for _, item in pairs(chest.list()) do
        if item.name == 'minecraft:lava_bucket' then
            count = count + 1
        end
    end
    return count
end

---Check if the chest is ful
---@return boolean
local function chest_full()
    local size = chest.size()
    local count = 0
    for _ in pairs(chest.list()) do
        count = count + 1
    end
    return count == size
end

local function main()
    local inv = peripheral.find('inventory')
    if inv == nil then
        telem:send_alert('no_chest', 'Could not find chest around turtle')
        log:fatal('Could not find chest around turtle')
    end
    ---@cast inv ccTweaked.peripherals.Inventory
    chest = inv

    while true do
        if chest_full() then
            telem:send_alert('chest_full', 'Chest has no space for lava buckets')
            log:fatal('Chest is full')
        end
        if cauldron_has_lava() then
            take_lava()
            telem:send_event('new_lava_bucket', 'Lava bucket was added', { count = count_buckets() })
        end
        sleep(1)
    end
end

telem:run_parallel_with('main', log:wrap_fn(main))
