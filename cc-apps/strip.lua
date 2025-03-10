local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/strip.log',
}
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

---@module 'ccl-actions'
local actions = require 'cc-libs.turtle.actions'

local args = { ... }
if #args < 3 then
    print('Usage: strip <length> <width> <depth> [direction|down]')
    print()
    print('Mine a square region to the right')
    print('WARNING this is for clearing areas, inventory will not be checked or dumped when full')
    print()
    print('Options:')
    print('    length: length of area to mine')
    print('    width: width of area to mine')
    print('    depth: depth of area to mine')
    print('    direction: up or down')
    return
end

local width = tonumber(args[1])
local length = tonumber(args[2])
local depth = tonumber(args[3])
local direction = args[4] or 'down'

assert(direction == 'up' or direction == 'down', 'Direction must be up or down')

log:info('Starting with parameters width=', width, 'length=', length, 'depth=', depth, 'direction=', direction)

local tmc = Motion:new()
tmc:enable_dig()

local function mine_layer(dig_up, dig_down)
    for z = 1, length do
        for x = 1, width do
            tmc:forward()
            if dig_up then
                turtle.digUp()
            end
            if dig_down then
                turtle.digDown()
            end
        end
        if z % 2 == 1 then
            tmc:right()
            tmc:forward()
            tmc:right()
        else
            tmc:left()
            tmc:forward()
            tmc:left()
        end
    end
end

if depth == 3 then
    tmc:down()
    mine_layer(true, true)
elseif depth < 3 then
    mine_layer(false, depth == 2)
end
