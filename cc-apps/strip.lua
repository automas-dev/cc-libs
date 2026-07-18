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

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

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

assert(type(length) == 'number' and length >= 1, 'length must be at least 1')
assert(type(width) == 'number' and width >= 1, 'width must be at least 1')
assert(type(height) == 'number' and height >= 1, 'height must be at least 1')

log:info('Starting with parameters length=', length, 'width=', width, 'height=', height, 'direction=', direction)

local map = Map:new()
local location = Location:new(map)
local tmc = Motion:new(location)
tmc:enable_dig()
local nav = Nav:new(map, tmc)

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

---@param side 'up'|'down'
local dig_vert = telem:span('dig_up', function(side)
    if side == 'up' then
        if turtle.detectUp() then
            turtle.digUp()
        end
        map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y + 1, location.pos.z))
    else
        if turtle.detectDown() then
            turtle.digDown()
        end
        map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y - 1, location.pos.z))
    end
end)

---Move to starting of first layer
---@return boolean
local lineup_start = telem:span('lineup_start', function()
    log:info('Heading to start')
    if turtle.detect() then
        turtle.dig()
    end
    if not tmc:forward() then
        return false
    end
    if height >= 3 then
        if direction == 'up' then
            dig_vert('up')
            if not tmc:up() then
                return false
            end
        else
            dig_vert('down')
            if not tmc:down() then
                return false
            end
        end
    end
    if height >= 2 then
        dig_vert(direction)
    end
    return true
end)

---Mine and move forward, then mine up and down if blocks exist
---@param dig_up boolean
---@param dig_down boolean
---@return boolean success
local mine_step = telem:span('mine_step', function(dig_up, dig_down)
    log:debug('Mining forward 1 step dig_up =', dig_up, 'dig_down =', dig_down)
    if not tmc:forward() then
        return false
    end
    if dig_up then
        dig_vert('up')
    end
    map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y + 1, location.pos.z))
    if dig_down then
        dig_vert('down')
    end
    map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y - 1, location.pos.z))
    return true
end)

---Mine forward n block mining up and down along the path
---@param n number
---@param dig_up boolean
---@param dig_down boolean
---@return boolean success
local mine_line = telem:span('mine_layer', function(n, dig_up, dig_down)
    log:debug('Mining line n =', n, 'dig_up =', dig_up, 'dig_down =', dig_down)
    for _ = 1, n do
        if not mine_step(dig_up, dig_down) then
            return false
        end
    end
    return true
end)

---Mine forward n block mining up and down along the path
---@param turn_direction 'left'|'right'
---@param dig_up boolean
---@param dig_down boolean
---@return boolean success
local turn_to_next = telem:span('turn_to_next', function(turn_direction, dig_up, dig_down)
    log:debug('Turning', direction, 'to next line')
    if turn_direction == 'left' then
        tmc:left()
    elseif turn_direction == 'right' then
        tmc:right()
    end
    if not tmc:forward() then
        return false
    end
    if dig_up then
        dig_vert('up')
    end
    if dig_down then
        dig_vert('down')
    end
    if turn_direction == 'left' then
        tmc:left()
    elseif turn_direction == 'right' then
        tmc:right()
    end
    return true
end)

---Mine a layer up to 3 blocks
---@param dig_up boolean
---@param dig_down boolean
---@return boolean
local mine_layer = telem:span('mine_layer', function(dig_up, dig_down)
    for z = 1, length do
        if not mine_line(width - 1, dig_up, dig_down) then
            return false
        end
        if z < length then
            if not turn_to_next(z % 2 == 1 and 'right' or 'left', dig_up, dig_down) then
                return false
            end
        end
    end
    return true
end)

---Navigate to the start
---@return boolean
local return_to_start = telem:span('return_to_start', function()
    local path = nav:find_path('start')
    log:trace('Path is', path)
    nav:follow_path(path)
    return true
end)

---Execute the mission
---@return boolean
local mission = telem:span('mission', function()
    -- Mine 3 layers at a time
    while height >= 3 do
        log:info('Mining layer of height 3')
        if not mine_layer(true, true) then
            return false
        end
        tmc:right()
        height = height - 3

        if height >= 1 then
            if direction == 'up' then
                if not tmc:up(height >= 3 and 3 or 2) then
                    return false
                end
                if height >= 2 then
                    dig_vert('up')
                end
            else
                if not tmc:down(height >= 3 and 3 or 2) then
                    return false
                end
                if height >= 2 then
                    dig_vert('down')
                end
            end
        end
    end

    -- Handle 1 or 2 remaining layers
    if height == 1 then
        log:info('Mining layer of height 1')
        return mine_layer(false, false)
    elseif height == 2 then
        log:info('Mining layer of height 2')
        return mine_layer(direction == 'up', direction == 'down')
    end

    return true
end)

local function main()
    local start_heading = nil
    nav:mark_poi('start')

    if lineup_start() then
        start_heading = location.heading
        mission()
    end

    if not return_to_start() then
        log:error('Failed to return to station')
        return false
    end

    if start_heading ~= nil then
        tmc:face(start_heading)
    end
    return true
end

telem:run_parallel_with('main', log:wrap_fn(main))
