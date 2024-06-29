local logging = require 'cc-libs.util.logging'
-- logging.file = 'stairs.log'
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'

local args = { ... }
if #args < 1 then
    print('Usage: stairs <n> [place stairs|false]')
    print()
    print('Options:')
    print('    n: number of steps')
    print('    place stairs: true will place stairs from slot 1')
    print()
    print('If stairs are being placed, n will be limited to the number of stairs in slot 1.')
    print('The height mined will also be increased to account for the steps')
    return
end

local n = tonumber(args[1])
local place_stairs = args[2] == 'true' or args[2] == 'yes'

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 4 * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    log:fatal('Not enough fuel! Need', fuel_need)
end

turtle.select(1)
if place_stairs and turtle.getItemCount(1) < n then
    log:fatal('Not enough stairs in slot 1, need', n)
end

local tmc = ccl_motion.Motion:new()
tmc:enable_dig()

tmc:up()

for i = 1, n do
    if turtle.getFuelLevel() == 0 then
        log:fatal('Ran out of fuel!')
    end

    tmc:forward()
    turtle.digUp()

    if place_stairs and i % 2 == 1 then
        tmc:up()
        turtle.digUp()
        if i < n then
            turtle.dig()
        end
        tmc:down()
    end

    tmc:down()
    turtle.digDown()
end

-- Return

log:info('Returning to station')

tmc:around()

for _ = 1, n do
    if place_stairs then
        turtle.placeDown()
    end
    tmc:up()
    tmc:forward()
end

tmc:around()
tmc:down()

log:info('Done!')
