local logging = require 'cc-libs.util.logging'
logging.basic_config{
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/ladder_up.log'
}
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local args = { ... }
if #args < 1 then
    print('Usage: ladder_up <height> [block_fill]')
    print()
    print("Dig forwards and lay a bridge on the way back if there isn't one already")
    print()
    print('Options:')
    print('    height: height of the ladder')
    print('    block_fill: name of block to place as column if there is an air gap')
    return
end

local height = tonumber(args[1])
local block_fill = args[2]

log:info('Starting with parameters height=', height, 'fill=', block_fill)

local tmc = Motion:new()
tmc:enable_dig()

local function place_fill()
    if block_fill == nil then
        return
    end
    if not turtle.inspect() then
        if actions.select_slot(block_fill) then
            turtle.place()
        else
            log:warning('Failed to find block', block_fill, 'for fill')
        end
    end
end

local function place_ladder()
    if not turtle.inspectUp() then
        if actions.select_slot('minecraft:ladder') then
            turtle.placeUp()
        else
            log:warning('Failed to find ladder')
        end
    end
end

-- Start

local total_height = 0

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

if tmc:backward() and actions.select_slot('minecraft:ladder') then
    turtle.place()
else
    log:warning('Failed to find ladder')
end
