-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/shaft_down.log',
}
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('shaft_down', 'Dig a shaft down and add walls if they are missing')
parser:add_arg('n', { help = 'number of blocks to mine down' })
parser:add_arg('block_walls', { help = 'name of block to place as walls' })
local args = parser:parse_args({ ... })

local n = tonumber(args.n)
local block_wall = args.block_wall

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    log:fatal('Not enough fuel! Need', fuel_need)
end

local tmc = Motion:new()
tmc:enable_dig()

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
    local total = 0
    for _ = 1, n do
        -- Can't move down, maybe we hit bedrock
        if not tmc:down() then
            break
        end
        place_all_sides()
        total = total + 1
    end

    -- Return

    log:info('Returning to station')

    -- Using total instead of n in case we stopped early
    tmc:up(total)

    log:info('Done!')
end

log:catch_errors(main)
