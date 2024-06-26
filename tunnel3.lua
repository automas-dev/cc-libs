local logging = require 'cc-libs.util.logging'
logging.file = 'tunnel3.log'
logging.level = logging.Level.INFO
logging.file_level = logging.Level.DEBUG
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local args = { ... }
if #args < 2 then
    print('Usage: tunnel3 <length> <block_floor> [block_ceiling]')
    print()
    print('Dig forwards and lay a bridge on the way back if there isn\'t one already')
    print()
    print('Options:')
    print('    length: length of the tunnel')
    print('    block_floor: name of block to place as ceiling')
    print('    block_ceiling: name of block to place as ceiling (defaults to no ceiling)')
    return
end

local length = tonumber(args[1])
local block_floor = args[2]
local block_ceiling = args[3]

log:info('Starting with parameters length=', length, 'floor=', block_floor, 'ceiling=', block_ceiling)

local function select_block(block_id)
    for i = 1, 16 do
        local info = turtle.getItemDetail(i)
        if info ~= nil then
            if info.name == block_id then
                turtle.select(i)
                return true
            end
        end
    end
    return false
end

local tmc = Motion:new()
tmc:enable_dig()

tmc:up()

local total_len = 0

for _ = 1, length do
    if block_ceiling ~= nil and not turtle.inspectUp() then
        if select_block(block_ceiling) then
            turtle.placeUp()
        else
            log:warning('Failed to find block', block_ceiling, 'for ceiling')
        end
    end
    tmc:forward()
    total_len = total_len + 1
end

if block_ceiling ~= nil and not turtle.inspectUp() then
    if select_block(block_ceiling) then
        turtle.placeUp()
    else
        log:warning('Failed to find block', block_ceiling, 'for ceiling')
    end
end

-- Return

log:info('Returning to station')

tmc:around()
tmc:down()

for _ = 1, total_len do
    if not turtle.inspectDown() then
        if select_block(block_floor) then
            turtle.placeDown()
        else
            log:warning('Failed to find block', block_floor, 'for floor')
        end
    end
    tmc:forward()
end

if not turtle.inspectDown() then
    if select_block(block_floor) then
        turtle.placeDown()
    else
        log:warning('Failed to find block', block_floor, 'for floor')
    end
end
tmc:around()

log:info('Done!')
