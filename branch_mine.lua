local logging = require 'cc-libs.util.logging'
logging.basic_config{
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'log/branch_mine.log'
}
logging.get_logger('map').level = logging.Level.WARNING
logging.get_logger('nav').file_level = logging.Level.TRACE
local log = logging.get_logger('main')

local FORWARD_MAX_TRIES = 10
local map_file = 'branch.map'

local cc_motion = require 'cc-libs.turtle.motion'
local Motion = cc_motion.Motion

local cc_map = require('cc-libs.map')
local Map = cc_map.Map

local rgps = require('cc-libs.turtle.rgps')
local RGPS = rgps.RGPS
local Compass = rgps.Compass

local cc_nav = require('cc-libs.turtle.nav')
local Nav = cc_nav.Nav

local args = { ... }
if #args < 2 then
    print('Usage: branch_mine <shafts> <length> [torch|8] [skip|0]')
    print()
    print('Options:')
    print('    shafts: number of shafts to mine')
    print('    length: length of each shaft')
    print('    torch:  interval to place torches')
    print('    skip:   number of shafts to skip')
    return
end

-- TODO don't crash if torch chest is empty

local shafts = tonumber(args[1])
local length = tonumber(args[2])
local torch = tonumber(args[3] or 8)
local skip = tonumber(args[4] or 0)

log:info('Starting with parameters shafts=', shafts, 'length=', length, 'torc=', torch, 'skip=', skip)

local map = Map:new()
if fs.exists(map_file) then
    map:load(map_file)
end
local gps = RGPS:new(map)
local tmc = Motion:new(gps)
local nav = Nav:new(tmc, gps, map)

local function debug_location()
    log:debug('Location is x=', gps.pos.x, 'z=', gps.pos.z, 'dir=', gps:direction_name())
end

local function assert_torch()
    local data = turtle.getItemDetail(1)
    if not data then
        log:fatal('No torches in 1st slot')
    end
    local total_shafts = shafts - skip
    local total_distance = total_shafts * 3 + total_shafts * length * 2
    local torch_need = math.ceil(total_distance / torch)
    log:debug('Torches needed is', torch_need)
    if data.count < torch_need then
        log:fatal('Not enough torches, need', torch_need)
    end
    if data.name ~= 'minecraft:torch' then
        log:fatal('Item in slot 1 is not torch')
    end
    turtle.select(1)
end

local function assert_fuel()
    log:info('Starting fuel level', turtle.getFuelLevel())
    local shafts_per_dump = 2
    local total_shafts = shafts - skip
    local total_distance = shafts * 6 + total_shafts * length * 2 + total_shafts * length * 2 / shafts_per_dump
    local fuel_need = math.ceil(1 + total_distance)
    log:debug('Fuel needed is', fuel_need)
    if turtle.getFuelLevel() < fuel_need then
        log:fatal('Not enough fuel! Need', fuel_need)
    end
end

local function inventory_full()
    return turtle.getItemCount(16) > 0
end

local function return_to_station()
    log:info('Returning to station')

    debug_location()
    nav:mark_resume()
    nav:back_follow()
end

local function dump()
    local state = {
        dir = gps.dir,
    }

    log:info('Inventory is full, dumping')
    log:debug('Current state is dir=', state.dir)

    return_to_station()

    -- Dump

    nav:face(Compass.E)

    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    log:info('Collecting more torches')
    nav:face(Compass.W)
    local success, err = turtle.suck(turtle.getItemSpace())
    log:debug('When sucking torches, got return', tostring(success))
    if not success then
        log:fatal('Could not pull torches from inventory:', err)
    end

    -- Resume

    log:info('Returning to mining')
    nav:follow()
    nav:face(state.dir)
end

local function try_forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')

    for _ = 1, n do
        local did_move = false
        for _ = 1, FORWARD_MAX_TRIES do
            if tmc:forward() then
                did_move = true
                break
            else
                log:debug('Could not move forward, trying to dig')
                turtle.dig()
            end
        end

        if not did_move then
            log:fatal('Failed to move forward after', FORWARD_MAX_TRIES, 'attempts')
        end
    end
end

local function dig_forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')

    for _ = 1, n do
        if turtle.getFuelLevel() == 0 then
            log:fatal('Ran out of fuel!')
        end

        if inventory_full() then
            dump()
        end

        turtle.dig()
        try_forward()
        turtle.digUp()

        local has_block, data = turtle.inspectDown()
        if has_block then
            if data.name ~= 'minecraft:torch' then
                turtle.digDown()
            end
        end
    end
end

local function place_torch()
    log:debug('Place torch')
    local data = turtle.getItemDetail(1)
    if not data then
        log:error('No torches in 1st slot')
        return false
    end
    if data.name ~= 'minecraft:torch' then
        log:error('Item in slot 1 is not torch')
        return_to_station()
        nav:face(Compass.N)
        tmc:down()
        return false
    end
    turtle.select(1)
    turtle.placeDown()
    return true
end

local function mine_shaft()
    log:debug('Mining shaft at z=', gps.pos.z, 'dir=', gps:direction_name())

    for i = 1, length do
        dig_forward()

        if i > 0 and i % torch == 0 then -- > 0 to prevent placing in tunnel
            if not place_torch() then
                return_to_station()
                nav:face(Compass.N)
                tmc:down()
                return false
            end
        end
    end
    return true
end

local function mine_tunnel()
    log:debug('Mining tunnel at z=', gps.pos.z)
    assert(gps.pos.x == 0, 'Mining tunnel but not at x=0')

    nav:face(Compass.N)

    for _ = 1, 3 do
        if gps.pos.z % torch == 1 then -- 1 is fix for gps starting a block behind
            if not place_torch() then
                return_to_station()
                nav:face(Compass.N)
                tmc:down()
                return false
            end
        end

        dig_forward()
    end

    nav:face(Compass.S)
    try_forward(3)
    return true
end

-- TODO
-- Smart check for inventory full
-- Check for fail to move
-- Don't mine fortune ores (eg. diamond)
-- Pickup fuel
-- Mine through wall to last shaft for dump

local function run()
    -- assert_torch() -- Disabled because of torch re-stock on dump
    assert_fuel()

    -- Move to start

    nav:reset()

    tmc:up()
    nav:reset()
    dig_forward()

    -- Skip shafts

    if skip > 0 then
        log:info('Skipping', skip, 'shafts')

        for _ = 1, skip do
            dig_forward(3)
        end
    end

    -- Mine each shaft

    for i = 1, shafts - skip do
        log:info('Starting shaft', i + skip)
        debug_location()

        if i == 1 then
            log:debug('First shaft, starting at center in tunnel')

            if not mine_tunnel() then
                return
            end

            -- Mine right half of shaft
            nav:face(Compass.E)
            mine_shaft()

            -- Mine left half of shaft
            nav:face(Compass.W)
            try_forward(length)
            if not mine_shaft() then
                return
            end
        else
            -- Turn to face next shaft
            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                nav:face(Compass.E)
            else
                log:debug('Shaft is odd so facing West')
                nav:face(Compass.W)
            end

            if not mine_shaft() then
                return
            end
            if not mine_tunnel() then
                return
            end

            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                nav:face(Compass.E)
            else
                log:debug('Shaft is odd so facing West')
                nav:face(Compass.W)
            end

            if not mine_shaft() then
                return
            end
        end

        -- Mine to start of next shaft and push
        if i < shafts then
            nav:face(Compass.N)
            dig_forward(3)
        end
    end

    -- Return

    return_to_station()

    nav:face(Compass.E)

    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    nav:face(Compass.N)
    tmc:down()
    debug_location()

    log:info('Writing map to file')

    map:dump(map_file)

    log:info('Done!')
end

run()
