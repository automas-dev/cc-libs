-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/branch_mine.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map
local MapClient = ccl_map.MapClient

local action = require 'cc-libs.turtle.actions'

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location
local Compass = ccl_location.Compass
local LocalFrame = ccl_location.LocalFrame

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

---@type MapClient
local map_client
---Map has been received from the server, updates should be sent to the server
local map_loaded = false

local heading_offset = 0

local map = Map:new()
local location = Location:new(map)
local tmc = Motion:new(location)
tmc:enable_dig()
local nav = Nav:new(map, tmc)

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

---@type LocalFrame
local local_frame

tmc.motion_fail_cb = function(move_action, reason)
    log:info('Stopping execution for motion error', move_action, reason)
    error('Motion error ' .. move_action .. ' ' .. reason)
end

local function debug_location()
    -- log:debug('Location is x=', location.pos.x, 'z=', location.pos.z, 'heading=', location:heading_name())
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

local function estimate_time()
    local shafts_per_dump = 2
    local total_shafts = shafts - skip
    local total_distance = shafts * 6 + total_shafts * length * 2 + total_shafts * length * 2 / shafts_per_dump
    local action_count = 4
    local action_time = 0.4 -- s/action
    local total_s = action_count * action_time * total_distance
    local total_m = total_s / 60
    log:info('This will take', total_s, 'seconds =', total_m, 'minutes')
end

local function inventory_full()
    return turtle.getItemCount(16) > 0
end

---Wrapper for Map:pos to add a point which also updates the remote map if connected
---@param pos Vec3|Point
local function add_map_point(pos)
    local exists = map:get_pos(pos.x, pos.y, pos.z)
    if exists == nil then
        map:pos(pos)
        if map_loaded then
            map_client:add_node(pos)
        end
    end
end

---Wrapper for Map:pos to add a point which also updates the remote map if connected
---@param pos Vec3|Point
local function add_map_waypoint(name, pos)
    map:add_waypoint(name, pos)
    if map_loaded then
        map_client:add_waypoint(name, pos)
    end
end

local function return_to_station()
    log:info('Returning to station')

    debug_location()
    nav:mark_poi('resume')
    if nav:get_poi('resume').id ~= nav:get_poi('station').id then
        nav:follow_path(nav:find_path('station'))
    end
    debug_location()
    log:debug('Finished returning to station')
end

local function dump()
    local state = {
        heading = location.heading,
    }

    log:info('Inventory is full, dumping')
    log:debug('Current state is heading=', state.heading)

    return_to_station()

    -- Dump

    tmc:face(Compass.EAST, heading_offset)

    -- TODO check if target inventory is full and stop
    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    log:info('Collecting more torches')
    tmc:face(Compass.WEST, heading_offset)
    local success, err = turtle.suck(turtle.getItemSpace())
    log:debug('When sucking torches, got return', tostring(success))
    if not success and not action.find_torch() then
        log:error('Out of torches and could not pull torches from inventory:', err)
        return false
    end

    -- Resume

    log:info('Returning to mining')
    nav:follow_path(nav:find_path('resume'))
    tmc:face(state.heading, heading_offset)

    return true
end

local function check_for_ore()
    local has_block, data
    has_block, data = turtle.inspect()
    if has_block then
        if string.match(data.name, 'ore') then
            telem:send_event('found_ore', 'Found ore ' .. data.name, { block = data })
            log:info('Found ore', data.name, 'near', location.pos, 'block =', data)
            return
        end
    end
    has_block, data = turtle.inspectUp()
    if has_block then
        if string.match(data.name, 'ore') then
            telem:send_event('found_ore', 'Found ore ' .. data.name, { block = data })
            log:info('Found ore', data.name, 'near', location.pos, 'block =', data)
            return
        end
    end
    has_block, data = turtle.inspectDown()
    if has_block then
        if string.match(data.name, 'ore') then
            telem:send_event('found_ore', 'Found ore ' .. data.name, { block = data })
            log:info('Found ore', data.name, 'near', location.pos, 'block =', data)
            return
        end
    end
end

local function dig_forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')

    for _ = 1, n do
        if turtle.getFuelLevel() == 0 then
            log:error('Ran out of fuel!')
            return false
        end

        if inventory_full() then
            if not dump() then
                return false
            end
        end

        check_for_ore()

        -- Detecting air is twice as fast as digging air (20 hz instead of 14 hz)
        if turtle.detect() then
            turtle.dig()
        end

        tmc:forward()

        if turtle.detectUp() then
            turtle.digUp()
        end

        local has_block, data = turtle.inspectDown()
        if has_block then
            if data.name ~= 'minecraft:torch' then
                turtle.digDown()
            end
        end

        -- here
        add_map_point(location.pos)
        -- above
        add_map_point(location.pos + Vec3:new(0, 1, 0))
        -- below
        add_map_point(location.pos - Vec3:new(0, 1, 0))
    end

    return true
end

local function place_torch()
    log:debug('Place torch')
    if action.select_slot('minecraft:torch') == nil then
        log:warning('No torches found')
        if not dump() then
            return false
        end
    end
    turtle.placeDown()
    log:debug('Placed torch')
    return true
end

local function mine_shaft()
    log:debug('Mining shaft at z=', location.pos.z, 'heading=', location:heading_name())

    for i = 1, length do
        if not dig_forward() then
            return false
        end

        if i > 0 and i % torch == 0 then -- > 0 to prevent placing in tunnel
            if not place_torch() then
                return false
            end
        end
    end
    return true
end

local function mine_tunnel()
    log:debug('Mining tunnel at z=', location.pos.z)
    -- local station = nav:get_poi('station')
    -- if station == nil then
    --     log:fatal('Missing station poi')
    --     -- Unreachable, but here so type checker knows that
    --     return
    -- end
    -- TODO make this the correct orientation
    -- assert(location.pos.x == station.x, 'Mining tunnel but not at x=' .. station.x .. ' got ' .. location.pos.x)

    tmc:face(Compass.NORTH, heading_offset)

    for _ = 1, 3 do
        local local_pos = local_frame:to_local(location.pos)
        log:debug('Transformed global', location.pos, 'to local', local_pos)
        if local_pos.z % torch == 1 then
            if not place_torch() then
                return false
            end
        end

        if not dig_forward() then
            return false
        end
    end

    tmc:face(Compass.SOUTH, heading_offset)
    tmc:forward(3)
    return true
end

local STATION_FILE = 'station.json'

---@return { heading: Compass?, relative: boolean }
local function load_station()
    local file = io.open(STATION_FILE, 'r')
    if file == nil then
        log:debug('Station file missing, creating new station state')
        return {
            heading = nil,
            relative = true,
        }
    end
    log:debug('Loading station')
    local data = json.decode(file:read('a'))
    file:close()
    log:trace('Finished loading station file')
    return data
end

local function store_station(station)
    log:debug('Storing station file')
    local file = assert(io.open(STATION_FILE, 'w'))
    file:write(json.encode(station))
    file:close()
    log:trace('Finished storing station file')
end

-- TODO
-- Smart check for inventory full
-- Don't mine fortune ores (eg. diamond)
-- Pickup fuel
-- Mine through wall to last shaft for dump

local function main()
    map_client = MapClient:new('server')
    local remote_map = map_client:get_map()
    if remote_map ~= nil then
        log:info('Loading map from server')
        map:from_table(remote_map)
        map_loaded = true
    else
        log:warning('Failed to fetch map from server')
        map_loaded = false
    end

    local station = load_station()

    -- assert_torch() -- Disabled because of torch re-stock on dump
    assert_fuel()
    estimate_time()

    -- Use relative heading for navigation if gps isn't available for heading
    if not location.has_fix then
        location.has_heading = true
    end

    -- Move to start

    local station_point = map:get_waypoint('station')
    if station_point ~= nil then
        log:debug('Found station waypoint', station_point)
        nav:poi_from_waypoint('station')
        local path_to_station = nav:find_path('station')
        log:debug('Path to station has', #path_to_station, 'points')
        if #path_to_station > 1 then
            log:info('Moving to station before starting')
            nav:follow_path(path_to_station)
            log:debug('Finished move to station')
        end
    else
        tmc:up()
        add_map_waypoint('station', location.pos)
        nav:poi_from_waypoint('station')
    end

    -- Save station heading if not already set
    if station.heading == nil or station.relative and location.has_fix then
        if not location.has_heading then
            log:debug('Attempting to get heading for station')
            tmc:forward()
            tmc:backward()
        end
        if location.has_fix and location.has_heading then
            log:debug('Have heading', location.heading, 'for station')
            station.heading = location.heading
            station.relative = false
            store_station(station)
        else
            log:debug('No heading for station, using relative NORTH')
            station.heading = Compass.NORTH
            station.relative = true
            store_station(station)
        end
    end

    local_frame = LocalFrame:new(location.pos, station.heading)

    -- Move out of station into start of first shaft
    if not dig_forward() then
        return false
    end

    heading_offset = station.heading - 1

    -- Skip shafts

    if skip > 0 then
        log:info('Skipping', skip, 'shafts')

        for _ = 1, skip do
            if not dig_forward(3) then
                return false
            end
        end
    end

    -- Mine each shaft

    shafts = shafts - skip
    for i = 1, shafts do
        log:info('Starting shaft', i + skip)
        debug_location()

        if i == 1 then
            log:debug('First shaft, starting at center in tunnel')

            -- Don't mine tunnel after last branch
            if i ~= shafts then
                if not mine_tunnel() then
                    break
                end
            end

            -- Mine right half of shaft
            tmc:face(Compass.EAST, heading_offset)
            if not mine_shaft() then
                break
            end

            -- Mine left half of shaft
            tmc:face(Compass.WEST, heading_offset)
            tmc:forward(length)
            if not mine_shaft() then
                break
            end
        else
            -- Turn to face next shaft
            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                tmc:face(Compass.EAST, heading_offset)
            else
                log:debug('Shaft is odd so facing West')
                tmc:face(Compass.WEST, heading_offset)
            end

            if not mine_shaft() then
                break
            end
            -- Don't mine tunnel after last branch
            if i ~= shafts then
                if not mine_tunnel() then
                    break
                end
            end

            if i % 2 == 0 then
                log:debug('Shaft is even so facing East')
                tmc:face(Compass.EAST, heading_offset)
            else
                log:debug('Shaft is odd so facing West')
                tmc:face(Compass.WEST, heading_offset)
            end

            if not mine_shaft() then
                break
            end
        end

        -- Mine to start of previous shaft
        if i - skip > 1 then
            tmc:face(Compass.SOUTH, heading_offset)
            if not dig_forward(2) then
                return false
            end
            tmc:face(Compass.NORTH, heading_offset)
            if not tmc:forward(2) then
                return false
            end
        end

        -- Mine to start of next shaft and push
        if i < shafts then
            tmc:face(Compass.NORTH, heading_offset)
            if not dig_forward(3) then
                return false
            end
        end
    end

    -- Return

    return_to_station()

    tmc:face(Compass.EAST, heading_offset)

    log:debug('At station, dumping inventory')
    for i = 2, 16 do
        turtle.select(i)
        while turtle.getItemCount() > 0 do
            turtle.drop()
        end
    end
    turtle.select(1)

    tmc:face(Compass.NORTH, heading_offset)
    tmc:down()
    debug_location()

    log:info('Done!')
end

-- log:catch_errors(main)
telem:run_parallel_with('main', log:wrap_fn(main))
