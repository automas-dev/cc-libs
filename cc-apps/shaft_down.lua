-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/shaft_down.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local actions = require 'cc-libs.turtle.actions'

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('shaft_down', 'Dig a shaft down and add walls if they are missing')
parser:add_arg('n', { help = 'number of blocks to mine down' })
parser:add_arg('block_wall', { help = 'name of block to place as walls' })
parser:add_option('l', 'ladder', 'place a ladder on the way back up')
local args = parser:parse_args({ ... })

local n = tonumber(args.n)
assert(n ~= nil)
local block_wall = args.block_wall
local place_ladder = args.ladder

log:info('Starting with parameters n=', n, 'block_wall=', block_wall, 'ladder=', place_ladder)

local tmc = Motion:new()
tmc:enable_dig()

local telem = get_telemetry()
telem:set_location(tmc.location)

local function place()
    if not turtle.detect() then
        if actions.select_slot(block_wall) then
            turtle.place()
        else
            log:warning('Failed to find block', block_wall, 'for wall')
        end
    end
end

local function place_all_sides()
    for _ = 1, 4 do
        place()
        tmc:right()
    end
end

local function main()
    actions.assert_fuel(n * 2)
    if place_ladder then
        actions.assert_items('minecraft:ladder', n)
    end

    local total = 0
    for _ = 1, n do
        -- Can't move down, maybe we hit bedrock
        if not tmc:try_down() then
            break
        end
        place_all_sides()
        total = total + 1
    end

    log:info('Returning to station')

    -- Using total instead of n in case we stopped early

    if place_ladder then
        for _ = 1, total do
            tmc:up()
            if actions.select_slot('minecraft:ladder') then
                turtle.placeDown()
            end
        end
    else
        tmc:up(total)
    end

    log:info('Done!')
end

telem:run_parallel_with('main', log:wrap_fn(main))
