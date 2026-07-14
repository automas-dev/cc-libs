-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/strip.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_nav = require 'cc-libs.turtle.nav'
local Nav = ccl_nav.Nav

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new(
    'strip',
    'Mine a region to the front and right of the turtle\n'
        .. 'WARNING this is for clearing areas, inventory will not be checked or dumped when full'
)
parser:add_arg('length', { help = 'length of area to mine' })
parser:add_arg('width', { help = 'width of area to mine' })
parser:add_arg('height', { help = 'height of area to mine' })
parser:add_option('u', 'up', 'mine up instead of down')
local args = parser:parse_args({ ... })

local length = tonumber(args.width)
local width = tonumber(args.length)
local height = tonumber(args.height)
local direction = args.up and 'up' or 'down'

assert(length >= 1, 'length must be at least 1')
assert(width >= 1, 'width must be at least 1')
assert(height >= 1, 'height must be at least 1')

log:info('Starting with parameters length=', length, 'width=', width, 'height=', height, 'direction=', direction)

local map = Map:new()
local location = Location:new(map)
local tmc = Motion:new(location)
local nav = Nav:new(map, tmc)

tmc:enable_dig()

-- TODO check if motion was successful

local function mine_layer(dig_up, dig_down)
    for z = 1, length do
        for x = 1, width do
            if dig_up then
                turtle.digUp()
            end
            if dig_down then
                turtle.digDown()
            end
            if x < width then
                tmc:forward()
            end
        end
        if z < length then
            if z % 2 == 1 then
                tmc:right()
                if dig_up then
                    turtle.digUp()
                end
                if dig_down then
                    turtle.digDown()
                end
                tmc:forward()
                tmc:right()
            else
                tmc:left()
                if dig_up then
                    turtle.digUp()
                end
                if dig_down then
                    turtle.digDown()
                end
                tmc:forward()
                tmc:left()
            end
        end
    end
end

local function main()
    nav:mark_poi('station')

    -- Mine 3 layers at a time
    while height >= 3 do
        log:debug('Mining layer of height 3')
        if direction == 'up' then
            tmc:up(2)
        else
            tmc:down(2)
        end
        mine_layer(true, true)
        tmc:around()
        height = height - 3
    end

    -- Handle 1 or 2 remaining layers
    if height == 1 then
        log:debug('Mining layer of height 1')
        mine_layer(false, false)
    elseif height == 2 then
        log:debug('Mining layer of height 2')
        mine_layer(direction == 'up', direction == 'down')
    end

    nav:mark_poi('resume')
    nav:follow_path(nav:find_path('station'))
    tmc:right()
end

log:catch_errors(main)
