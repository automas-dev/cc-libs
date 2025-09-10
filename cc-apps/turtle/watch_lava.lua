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

local actions = require 'cc-libs.turtle.actions'

local function cauldron_has_lava()
    local exists, data = turtle.inspect()
    return exists and data.name == 'minecraft:lava_cauldron'
end

local function take_lava()
    log:info('Taking lava from cauldron')

    if not actions.select_slot('minecraft:bucket') then
        log:fatal('No more buckets')
    end

    if not turtle.place() then
        log:fatal('Failed to extract lava')
    end

    log:trace('Got lava bucket')

    if not actions.select_slot('minecraft:lava_bucket') then
        log:error('Failed to select lava bucket')
    else
        turtle.dropDown()
        log:debug('Pushed lava bucket into chest bellow')
    end
end

local function run()
    while true do
        if cauldron_has_lava() then
            take_lava()
        end
        sleep(1)
    end
end

log:catch_errors(run)
