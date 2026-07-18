package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/tunnel.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_nav = require 'cc-libs.turtle.nav'
local Nav = ccl_nav.Nav

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('tunnel', 'Dig a 3x3 tunnel')
parser:add_arg('length', { help = 'length of the tunnel' })
local args = parser:parse_args({ ... })

local length = args.length

local map = Map:new()
local location = Location:new(map)
local tmc = Motion:new(location)
tmc:enable_dig()
local nav = Nav:new(map, tmc)

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

local lineup_start = telem:span('lineup_start', function()
    if not tmc:up() then
        return false
    end
    tmc:right()
    if not tmc:forward() then
        return false
    end
    tmc:left()
    return true
end)

---Mine and move forward, then mine up and down if blocks exist
---@return boolean success
local mine_step = telem:span('mine_step', function()
    if turtle.detect() then
        turtle.dig()
    end
    if not tmc:forward() then
        return false
    end
    if turtle.detectUp() then
        turtle.digUp()
    end
    map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y + 1, location.pos.z))
    if turtle.detectDown() then
        turtle.digDown()
    end
    map:link(map:pos(location.pos), map:point(location.pos.x, location.pos.y - 1, location.pos.z))
    return true
end)

---Mine forward n block mining up and down along the path
---@param n number
---@return boolean success
local mine_line = telem:span('mine_layer', function(n)
    for _ = 1, n do
        if not mine_step() then
            return false
        end
    end
    return true
end)

---Mine forward n block mining up and down along the path
---@param direction 'left'|'right'
---@return boolean success
local turn_to_next = telem:span('turn_to_next', function(direction)
    if direction == 'left' then
        tmc:left()
    elseif direction == 'right' then
        tmc:right()
    end
    if not tmc:forward() then
        return false
    end
    turtle.digUp()
    turtle.digDown()
    if direction == 'left' then
        tmc:left()
    elseif direction == 'right' then
        tmc:right()
    end
    return true
end)

local return_to_start = telem:span('return_to_start', function()
    local path = nav:find_path('start')
    log:trace('Path is', path)
    nav:follow_path(path)
    return true
end)

-- Main function
local function main()
    if location.has_fix and not location.has_heading then
        if not tmc:forward() or not tmc:backward() then
            error('Motion to acquire heading failed')
        end
    end

    local start_heading = location.heading
    nav:mark_poi('start')

    ---@type [fun(...): ..., ...][]
    local mission = {
        { lineup_start },
        { mine_line, { length } },
        { turn_to_next, { 'left' } },
        { mine_line, { length } },
        { turn_to_next, { 'right' } },
        { mine_line, { length } },
    }

    for i, step in ipairs(mission) do
        local fn = step[1]
        local success, res = fn(table.unpack(step[2] or {}))
        if not success then
            log:error('Failed on step', i, { i = i, step = step, success = success, res = res })
            break
        end
    end

    if not return_to_start() then
        log:error('Failed to return to station')
        return false
    end

    tmc:face(start_heading)
    return true
end

-- Call main and log an error if raised
telem:run_parallel_with('main', log:wrap_fn(main))
