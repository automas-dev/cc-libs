package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/harvest_crops.log',
}
local log = logging.get_logger('main')

local vec = require 'cc-libs.util.vec'
local vec3 = vec.vec3

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('farm', 'Harvest crops from the bottom right corner')
parser:add_arg('width', { help = 'plot width' })
parser:add_arg('length', { help = 'plot length' })
local args = parser:parse_args({ ... })

local width = tonumber(args.width)
local length = tonumber(args.length)

log:info('Start farm with width=', width, 'length=', length)

local ccl_motion = require 'cc-libs.turtle.controller'
local MotionController = ccl_motion.MotionController

local ccl_location = require 'cc-libs.turtle.location'
local Compass = ccl_location.Compass

local actions = require 'cc-libs.turtle.actions'

local tmc = MotionController:new()
tmc.location.debug_location = true

local seed_name_map = {
    ['minecraft:wheat'] = 'minecraft:wheat_seeds',
    ['minecraft:potatoes'] = 'minecraft:potato',
    ['minecraft:carrots'] = 'minecraft:carrot',
}

local home = vec3(1564, 69, -699)

local function return_home()
    local pos = tmc.location.pos
    local delta = home - pos

    log:info('Returning to home')
    log:debug('Delta from', pos, 'to home', home, 'is', delta)

    if delta.z > 0 then
        tmc:face(Compass.SOUTH)
    elseif delta.z < 0 then
        tmc:face(Compass.NORTH)
    end

    tmc:forward(math.abs(delta.z))

    log:trace('Finished z axis motion')

    if delta.x > 0 then
        tmc:face(Compass.EAST)
    elseif delta.x < 0 then
        tmc:face(Compass.WEST)
    end

    tmc:forward(math.abs(delta.x))
    tmc:face(Compass.SOUTH)

    log:trace('Finished x axis motion')

    if pos.y > home.y then
        tmc:down(pos.y - home.y)
    elseif pos.y < home.y then
        log:fatal('Why are you underground?')
    end

    log:trace('Finished y axis motion')
end

local function replant(name)
    log:debug('Replant', name)
    local seed_name = seed_name_map[name]
    log:debug('Selecting seed name', seed_name)
    if not seed_name then
        log:warning('Could not find seed name for', name)
        return
    end
    if not actions.select_slot(seed_name) then
        log:warning('Failed to find', seed_name, 'to replant')
        return
    end
    turtle.placeDown()
end

local function harvest_crops()
    log:info('Harvesting crops')

    tmc:up()
    tmc:forward()
    for x = 1, width do
        for z = 1, length do
            local exists, info = turtle.inspectDown()
            if exists and info.state ~= nil then
                if info.state.age == 7 then
                    log:debug('Harvest crop', info.name, 'at', x, z)
                    turtle.digDown()
                    replant(info.name)
                end
            end
            if z < length then
                tmc:forward()
            end
        end

        if x < width then
            if x % 2 == 1 then
                tmc:left()
                tmc:forward()
                tmc:left()
            else
                tmc:right()
                tmc:forward()
                tmc:right()
            end
        end
    end

    if width % 2 == 1 then
        tmc:around()
        tmc:forward(length)
    else
        tmc:forward()
    end

    log:info('Finished harvest')

    return_home()

    for i = 1, 16 do
        actions.dump_slot(i, 'down')
    end

    log:debug('Finished dumping inventory')
end

local function run()
    if tmc.location.has_fix and tmc.location.pos ~= home then
        log:warning('Did not start at home, may have been unloaded')
        if not turtle.detect() then
            tmc:forward()
        else
            tmc:backward()
        end
        if not tmc.location.has_heading then
            log:fatal('Could not acquire heading to return home')
        else
            log:info('Returning to home before starting harvest')
            return_home()
        end
    end

    while true do
        harvest_crops()
        sleep(60 * 20)
    end
end

log:catch_errors(run)
