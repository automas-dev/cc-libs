package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    filepath = 'logs/bridge.log',
}
local log = logging.get_logger('main')

local argparse = require 'cc-libs.util.argparse'
local parser =
    argparse.ArgParse:new('bridge', "Dig forwards and lay a bridge on the way back if there isn't one already")
parser:add_arg('length', { help = 'length of bridge/tunnel' })
parser:add_arg('block_floor', { help = 'name of block to place as floor' })
parser:add_arg(
    'block_ceiling',
    { help = 'name of block to place as ceiling (defaults to no ceiling)', required = false }
)
local args = parser:parse_args({ ... })

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local length = tonumber(args.length)
local block_floor = args.block_floor
local block_ceiling = args.block_ceiling

local tmc = Motion:new()
tmc:enable_dig()

local function ceiling()
    if block_ceiling ~= nil and not turtle.detectUp() then
        if actions.select_slot(block_ceiling) then
            turtle.placeUp()
        else
            log:warning('Failed to find block', block_ceiling, 'for ceiling')
        end
    end
end

local function floor()
    if not turtle.detectDown() then
        if actions.select_slot(block_floor) then
            turtle.placeDown()
        else
            log:warning('Failed to find block', block_floor, 'for floor')
        end
    end
end

log:info('Starting with parameters length=', length, 'floor=', block_floor, 'ceiling=', block_ceiling)

local total_len = 0

for _ = 1, length do
    floor()
    tmc:forward()
    total_len = total_len + 1
end

floor()
tmc:around()

-- Return

log:info('Returning to station')
tmc:up()

for _ = 1, total_len do
    ceiling()
    tmc:forward()
end

ceiling()
tmc:around()
tmc:down()

log:info('Done!')
