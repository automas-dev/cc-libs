-- Remember to update README.md with any changes here
-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/lava_lake_refuel.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('lava_lake_refuel', 'Refuel turtle from a lava lake by giving it a bucket')
parser:add_arg('limit', { help = 'fuel level limit before returning', required = false })
local args = parser:parse_args({ ... })

-- Import libraries
local actions = require 'cc-libs.turtle.actions'

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

-- Gather arguments
local n = args.new

-- Create objects
local tmc = Motion:new()
tmc:enable_dig()

-- Main function
local function main()
    if not actions.select_slot('minecraft:bucket') then
        log:error('Please give me a bucket')
        return
    end

    local total = 0

    while true do
        if not tmc:forward() then
            break
        end
        total = total + 1
        local exists, info = turtle.inspectDown()
        if exists and info.name == 'minecraft:lava' then
            turtle.placeDown()
            turtle.refuel()
        else
            break
        end
    end
    tmc:around()
    tmc:forward(total)
    tmc:around()
end

-- Call main and log an error if raised
log:catch_errors(main)
