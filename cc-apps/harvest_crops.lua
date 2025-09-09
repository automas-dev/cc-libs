package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/harvest_crops.log',
}
local log = logging.get_logger('main')

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

local actions = require 'cc-libs.turtle.actions'

local tmc = MotionController:new()
tmc.location.debug_location = true

local seed_name_map = {
    ['minecraft:wheat'] = 'minecraft:wheat_seeds',
    ['minecraft:potatoes'] = 'minecraft:potato',
    ['minecraft:carrots'] = 'minecraft:carrot',
}

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

    tmc:left()
    tmc:forward(width - 1)
    tmc:left()
    tmc:down()

    for i = 1, 16 do
        actions.dump_slot(i, 'down')
    end

    log:debug('Finished dumping inventory')
end

local function run()
    while true do
        harvest_crops()
        sleep(60 * 20)
    end
end

log:catch_errors(run)
