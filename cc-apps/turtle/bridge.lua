package.path = '../../?.lua;../../?/init.lua;' .. package.path
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
parser:add_option('r', 'replace_floor', 'Replace existing floor if it does not match')
local args = parser:parse_args({ ... })

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local telemetry = require 'cc-libs.telemetry'

local length = tonumber(args.length)
local block_floor = args.block_floor
local block_ceiling = args.block_ceiling
local replace_floor = args.replace_floor

if not actions.find_slot(block_floor, 1) then
    log:fatal('Could not find block', block_floor, 'in inventory')
end

if block_ceiling and not actions.find_slot(block_ceiling, 1) then
    log:fatal('Could not find block', block_ceiling, 'in inventory')
end

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
    local exists, info = turtle.inspectDown()
    if replace_floor and exists and info.name ~= block_floor then
        log:trace('Replacing', info.name, 'floor')
        turtle.digDown()
        exists = false
    end
    if not exists then
        if actions.select_slot(block_floor) then
            turtle.placeDown()
        else
            log:warning('Failed to find block', block_floor, 'for floor')
        end
    end
end

local total_len = 0

local function run_out()
    log:info('Starting with parameters length=', length, 'floor=', block_floor, 'ceiling=', block_ceiling)

    for _ = 1, length do
        floor()
        tmc:forward()
        total_len = total_len + 1
    end

    floor()
    tmc:around()
end

local function run_return()
    log:info('Returning to station')
    tmc:up()

    for _ = 1, total_len do
        ceiling()
        tmc:forward()
    end

    ceiling()
    tmc:around()
    tmc:down()
end

telemetry.run_with_telemetry(log.catch_errors, log, run_out)
telemetry.run_with_telemetry(log.catch_errors, log, run_return)
