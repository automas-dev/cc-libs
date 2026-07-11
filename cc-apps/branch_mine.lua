-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/branch_mine.log',
}
local log = logging.get_logger('main')

local FORWARD_MAX_TRIES = 10
local map_file = 'branch_map.json'

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location
local Compass = ccl_location.Compass

local ccl_nav = require 'cc-libs.turtle.nav'
local Nav = ccl_nav.Nav

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new(
    'branch_mine',
    'Starting on the floor, mine 3 block high branches to the left / right and place torches'
)
parser:add_arg('shafts', { help = 'number of shafts to mine' })
parser:add_arg('length', { help = 'length of each shaft' })
parser:add_arg('torch', { help = 'interval to place torches', required = false, default = 8 })
parser:add_arg('skip', { help = 'number of shafts to skip', required = false, default = 0 })
local args = parser:parse_args({ ... })

-- TODO don't crash if torch chest is empty

local shafts = tonumber(args.shafts)
local length = tonumber(args.length)
local torch = tonumber(args.torch)
local skip = tonumber(args.skip)

log:info('Starting with parameters shafts=', shafts, 'length=', length, 'torc=', torch, 'skip=', skip)

-- TODO fix link error when using loaded map
local map = Map:new()
if fs.exists(map_file) then
    log:warning('LOAD MAP IS DISABLED')
    -- map:load(map_file)
end
local location = Location:new(map)
local tmc = Motion:new(location)
local nav = Nav:new(map, location)

local telem = get_telemetry()
telem:set_location(location)

local function debug_location()
    log:debug('Location is x=', location.pos.x, 'z=', location.pos.z, 'heading=', location:heading_name())
end

local function assert_torch()
    local data = turtle.getItemDetail(1)
    if not data then
        log:fatal('No torches in 1st slot')
        return -- not reachable, here for linter
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
    nav:mark_poi('resume')
    tmc:follow_path(nav:find_path('resume', 'station'))
end

local function dump()
    local state = {
        heading = location.heading,
    }

    log:info('Inventory is full, dumping')
    log:debug('Current state is heading=', state.heading)

    return_to_station()

    -- Dump

    tmc:face(Compass.EAST)

    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    log:info('Collecting more torches')
    tmc:face(Compass.WEST)
    local success, err = turtle.suck(turtle.getItemSpace())
    log:debug('When sucking torches, got return', tostring(success))
    if not success then
        log:fatal('Could not pull torches from inventory:', err)
    end

    -- Resume

    log:info('Returning to mining')
    tmc:follow_path(nav:find_path('station', 'resume'))
    tmc:face(state.heading)
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
        tmc:face(Compass.NORTH)
        tmc:down()
        return false
    end
    turtle.select(1)
    turtle.placeDown()
    return true
end

local function mine_shaft()
    log:debug('Mining shaft at z=', location.pos.z, 'heading=', location:heading_name())

    for i = 1, length do
        dig_forward()

        if i > 0 and i % torch == 0 then -- > 0 to prevent placing in tunnel
            if not place_torch() then
                return_to_station()
                tmc:face(Compass.NORTH)
                tmc:down()
                return false
            end
        end
    end
    return true
end

local function mine_tunnel()
    log:debug('Mining tunnel at z=', location.pos.z)
    assert(location.pos.x == 0, 'Mining tunnel but not at x=0')

    tmc:face(Compass.NORTH)

    for _ = 1, 3 do
        if location.pos.z % torch == 1 then -- 1 is fix for gps starting a block behind
            if not place_torch() then
                return_to_station()
                tmc:face(Compass.NORTH)
                tmc:down()
                return false
            end
        end

        dig_forward()
    end

    tmc:face(Compass.SOUTH)
    try_forward(3)
    return true
end

-- TODO
-- Smart check for inventory full
-- Check for fail to move
-- Don't mine fortune ores (eg. diamond)
-- Pickup fuel
-- Mine through wall to last shaft for dump

local function main()
    -- assert_torch() -- Disabled because of torch re-stock on dump
    assert_fuel()

    -- Use relative heading for navigation if gps isn't available for heading
    if not location.has_fix then
        location.has_heading = true
    end

    -- Move to start

    tmc:up()
    nav:mark_poi('station')
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
            tmc:face(Compass.EAST)
            mine_shaft()

            -- Mine left half of shaft
            tmc:face(Compass.WEST)
            try_forward(length)
            if not mine_shaft() then
                return
            end
        else
            -- Turn to face next shaft
            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                tmc:face(Compass.EAST)
            else
                log:debug('Shaft is odd so facing West')
                tmc:face(Compass.WEST)
            end

            if not mine_shaft() then
                return
            end
            if not mine_tunnel() then
                return
            end

            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                tmc:face(Compass.EAST)
            else
                log:debug('Shaft is odd so facing West')
                tmc:face(Compass.WEST)
            end

            if not mine_shaft() then
                return
            end
        end

        -- Mine to start of next shaft and push
        if i < shafts then
            tmc:face(Compass.NORTH)
            dig_forward(3)
        end
    end

    -- Return

    return_to_station()

    tmc:face(Compass.EAST)

    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    tmc:face(Compass.NORTH)
    tmc:down()
    debug_location()

    log:info('Writing map to file')

    map:dump(map_file)

    log:info('Done!')
end

telem:run_parallel_with(log.catch_errors, log, main)
