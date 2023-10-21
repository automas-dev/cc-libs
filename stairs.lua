local logging = require 'cc-libs.logging'
logging.file = 'stairs.log'
local log = logging.get_logger('main')

local MOVE_MAX_TRIES = 10

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

local function try_forward()
    local did_move = false
    for _ = 1, MOVE_MAX_TRIES do
        if turtle.forward() then
            did_move = true
            break
        else
            log:debug('Could not move forward, trying to dig')
            turtle.dig()
        end
    end

    if not did_move then
        log:fatal('Failed to move forward after', MOVE_MAX_TRIES, 'attempts')
    end
end

local function try_down()
    local did_move = false
    for _ = 1, MOVE_MAX_TRIES do
        if turtle.down() then
            did_move = true
            break
        else
            log:debug('Could not move down, trying to dig down')
            turtle.digDown()
        end
    end

    if not did_move then
        log:fatal('Failed to move down after', MOVE_MAX_TRIES, 'attempts')
    end
end

local function try_up()
    local did_move = false
    for _ = 1, MOVE_MAX_TRIES do
        if turtle.up() then
            did_move = true
            break
        else
            log:debug('Could not move up, trying to dig down')
            turtle.digUp()
        end
    end

    if not did_move then
        log:fatal('Failed to move up after', MOVE_MAX_TRIES, 'attempts')
    end
end

turtle.up()

for i = 1, n do
    if turtle.getFuelLevel() == 0 then
        log:fatal('Ran out of fuel!')
    end

    turtle.dig()
    try_forward()
    turtle.digUp()

    if place_stairs and i % 2 == 1 then
        try_up()
        turtle.digUp()
        if i < n then
            turtle.dig()
        end
        try_down()
    end

    turtle.digDown()
    try_down()
    turtle.digDown()
end

-- Return

log:info('Returning to station')

turtle.turnRight()
turtle.turnRight()

for _ = 1, n do
    if place_stairs then
        turtle.placeDown()
    end
    try_up()
    try_forward()
end

turtle.turnRight()
turtle.turnRight()
turtle.down()

log:info('Done!')
