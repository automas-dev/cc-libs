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

local actions = require 'cc-libs.turtle.actions'
local inventory = require 'cc-libs.turtle.inventory'

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
parser:add_option(nil, 'dump', 'return to start and dump inventory into chest behind start when full')
local args = parser:parse_args({ ... })

local length = tonumber(args.length)
local width = tonumber(args.width)
local height = tonumber(args.height)
local direction = args.up and 'up' or 'down'
local dump_when_full = args.dump

assert(type(length) == 'number' and length >= 1, 'length must be at least 1')
assert(type(width) == 'number' and width >= 1, 'width must be at least 1')
assert(type(height) == 'number' and height >= 1, 'height must be at least 1')

log:info(
    'Starting with parameters length=',
    length,
    'width=',
    width,
    'height=',
    height,
    'direction=',
    direction,
    'dump=',
    dump_when_full
)

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
        map:point(location.pos.x, location.pos.y + 1, location.pos.z)
    else
        if turtle.detectDown() then
            turtle.digDown()
        end
        map:point(location.pos.x, location.pos.y - 1, location.pos.z)
    end
end)

---Move to starting of first layer
local lineup_start = telem:span('lineup_start', function()
    log:info('Heading to start')
    if turtle.detect() then
        turtle.dig()
    end
    tmc:forward()
    if height >= 3 then
        if direction == 'up' then
            dig_vert('up')
            tmc:up()
        else
            dig_vert('down')
            tmc:down()
        end
    end
    if height >= 2 then
        dig_vert(direction)
    end
end)

---Navigate to the start
local return_to_start = telem:span('return_to_start', function()
    local path = nav:find_path('start')
    log:debug('Path is', path)
    nav:follow_path(path)
    return path
end)

local drop_items = telem:span('drop_items', function()
    log:debug('At station, dumping inventory')
    for i = 1, 16 do
        actions.dump_slot(i)
    end
    turtle.select(1)
end)

---Navigate to the start
local dump = telem:span('dump', function()
    local heading = location.heading
    nav:mark_poi('resume')
    local path = return_to_start()
    drop_items()
    local path_inv = {}
    log:debug('Starting reverse from', #path, 'points')
    for i = 1, #path do
        path_inv[i] = path[#path - (i - 1)]
    end
    nav:follow_path(path_inv)
    tmc:face(heading)
end)

local function check_full()
    if dump_when_full and inventory.full() then
        dump()
    end
end

---Mine and move forward, then mine up and down if blocks exist
---@param dig_up boolean
---@param dig_down boolean
local mine_step = telem:span('mine_step', function(dig_up, dig_down)
    log:trace('Mining forward 1 step dig_up =', dig_up, 'dig_down =', dig_down)
    tmc:forward()
    check_full()
    if dig_up then
        dig_vert('up')
        check_full()
    end
    if dig_down then
        dig_vert('down')
        check_full()
    end
    return true
end)

---Mine forward n block mining up and down along the path
---@param n number
---@param dig_up boolean
---@param dig_down boolean
local mine_line = telem:span('mine_layer', function(n, dig_up, dig_down)
    log:debug('Mining line n =', n, 'dig_up =', dig_up, 'dig_down =', dig_down)
    for _ = 1, n do
        mine_step(dig_up, dig_down)
    end
end)

---Mine forward n block mining up and down along the path
---@param turn_direction 'left'|'right'
---@param dig_up boolean
---@param dig_down boolean
local turn_to_next = telem:span('turn_to_next', function(turn_direction, dig_up, dig_down)
    log:debug('Turning', direction, 'to next line')
    if turn_direction == 'left' then
        tmc:left()
    elseif turn_direction == 'right' then
        tmc:right()
    end
    tmc:forward()
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
end)

---Mine a layer up to 3 blocks
---@param l number
---@param w number
---@param dig_up boolean
---@param dig_down boolean
local mine_layer = telem:span('mine_layer', function(l, w, dig_up, dig_down)
    for z = 1, w do
        mine_line(l - 1, dig_up, dig_down)
        if z < w then
            turn_to_next(z % 2 == 1 and 'right' or 'left', dig_up, dig_down)
        end
    end
end)

---Execute the mission
local mission = telem:span('mission', function()
    -- Mine 3 layers at a time
    local l = length
    local w = width
    while height >= 3 do
        log:info('Mining layer of height 3')
        mine_layer(l, w, true, true)
        tmc:right()
        if w % 2 == 1 then
            tmc:right()
        end
        height = height - 3

        if height >= 1 then
            if direction == 'up' then
                tmc:up(height >= 3 and 3 or 2)
                if height >= 2 then
                    dig_vert('up')
                end
            else
                tmc:down(height >= 3 and 3 or 2)
                if height >= 2 then
                    dig_vert('down')
                end
            end
        end
        if w % 2 == 0 then
            local old_l = l
            l = w
            w = old_l
            -- TODO does this work?
            -- l, w = w, l
        end
    end

    -- Handle 1 or 2 remaining layers
    if height == 1 then
        log:info('Mining layer of height 1')
        mine_layer(l, w, false, false)
    elseif height == 2 then
        log:info('Mining layer of height 2')
        mine_layer(l, w, direction == 'up', direction == 'down')
    end
end)

local function main()
    local start_heading = nil
    nav:mark_poi('start')

    if pcall(lineup_start) then
        start_heading = location.heading
        mission()
    end

    return_to_start()

    if dump_when_full then
        drop_items()
    end

    if start_heading ~= nil then
        tmc:face(start_heading)
    end
end

telem:run_parallel_with('main', log:wrap_fn(main))
