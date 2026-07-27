-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/ladder_up.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('ladder_up', 'Build a ladder, placing ladder blocks bellow the turtle')
parser:add_arg('height', { help = 'height of the ladder' })
parser:add_arg('block_fill', { help = 'name of block to place as column if there is an air gap', required = false })
local args = parser:parse_args({ ... })

local height = tonumber(args.height)
local block_fill = args.block_fill

log:info('Starting with parameters height=', height, 'fill=', block_fill)

local tmc = Motion:new()
tmc:enable_dig()

local function place_fill()
    if block_fill == nil then
        return
    end
    if not turtle.detect() then
        if actions.select_slot(block_fill) then
            turtle.place()
        else
            log:warning('Failed to find block', block_fill, 'for fill')
        end
    end
end

local function place_ladder()
    if not turtle.detectUp() then
        if actions.select_slot('minecraft:ladder') then
            turtle.placeUp()
        else
            log:warning('Failed to find ladder')
        end
    end
end

local function main()
    local total_height = 0

    -- Start

    place_fill()

    for _ = 1, height - 1 do
        if not tmc:up() then
            log:warning('Failed to move after', total_height, 'blocks, returning to start')
            break
        end
        place_fill()
        total_height = total_height + 1
    end

    -- Return

    log:info('Returning after', total_height, 'blocks')

    for _ = 1, total_height do
        tmc:down()
        place_ladder()
    end

    log:info('Placing final ladder')

    if tmc:try_backward() and actions.select_slot('minecraft:ladder') then
        turtle.place()
    else
        log:warning('Failed to find ladder')
    end
end

log:catch_errors(main)
