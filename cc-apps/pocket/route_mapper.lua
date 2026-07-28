package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.WARNING,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_route_mapper.log',
}
local log = logging.get_logger('main')

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient
local Map = ccl_map.Map

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local location = Location:new()
local telem = get_telemetry()
telem:set_location(location)

local GPS_TIMEOUT = 2

---@type MapClient
local client
---@type Map
local map

---Check if another point is inline with one of this points axis (ie. 2 axes match)
---@param a { x: number, y: number, z:number }
---@param b { x: number, y: number, z:number }
---@return boolean
local function inline(a, b)
    if a.x ~= b.x then
        return a.y == b.y and a.z == b.z
    elseif a.y ~= b.y then
        return a.x == b.x and a.z == b.z
    elseif a.z ~= b.z then
        return a.x == b.x and a.y == b.y
    else
        return true
    end
end

local function print_toolbar()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    local _, h = term.getSize()
    -- Clear the toolbar line and move cursor to the start
    term.setCursorPos(1, h)
    term.clearLine()
    -- Print toolbar
    write('h|f|e|r')
    term.setCursorBlink(false)
end

local function clear_term()
    term.setBackgroundColor(colors.black)
    term.clear()
    print_toolbar()
end

---Scroll the terminal, print line then re-add the bottom toolbar
---@param line string
local function scroll_term(line, error)
    local _, h = term.getSize()
    -- Clear the toolbar line and move cursor to the start
    term.setCursorPos(1, h)
    term.clearLine()
    -- Print lines
    term.setBackgroundColor(colors.black)
    term.setTextColor(error and colors.red or colors.lightGray)
    write(line)
    -- Scroll lines
    term.scroll(1)
    -- Print toolbar
    print_toolbar()
end

local function clear_pos(x, y, z)
    map:unmask_pos(x, y, z)
    local point = map:get_pos(x, y, z)
    if point then
        log:info('Removing point', point.id)
        map:remove_point(point.id)
    else
        log:debug('Point does not exist at', { x = x, y = y, z = z })
    end
    map:mask_pos(x, y, z)
end

---Save a route as a one way path
---@param name string
---@param markers {x: number, y: number, z:number}[]
local function save_route(name, markers)
    for i = 2, #markers do
        local p1 = markers[i - 1]
        local p2 = markers[i]
        if p1.x ~= p2.x then
            log:info('X from', p1.x, 'to', p2.x)
            local x_min = math.min(p1.x, p2.x)
            local x_max = math.max(p1.x, p2.x)
            for x = x_min, x_max do
                log:debug('x', x)
                clear_pos(x, p1.y, p1.z)
            end
        elseif p1.y ~= p2.y then
            log:info('Y from', p1.y, 'to', p2.y)
            local y_min = math.min(p1.y, p2.y)
            local y_max = math.max(p1.y, p2.y)
            for y = y_min, y_max do
                log:debug('y', y)
                clear_pos(p1.x, y, p1.z)
            end
        elseif p1.z ~= p2.z then
            log:info('Z from', p1.z, 'to', p2.z)
            local z_min = math.min(p1.z, p2.z)
            local z_max = math.max(p1.z, p2.z)
            for z = z_min, z_max do
                log:debug('z', z)
                clear_pos(p1.x, p1.y, z)
            end
        end
        map:unmask_pos(p1.x, p1.y, p1.z)
        map:unmask_pos(p2.x, p2.y, p2.z)
        map:dir_link(p1, p2, 2)
        map:mask_pos(p1.x, p1.y, p1.z)
        map:mask_pos(p2.x, p2.y, p2.z)
    end
end

local function main()
    client = MapClient:new('server')
    map = Map:new(client)

    clear_term()

    local markers = {}

    while true do
        local res = { os.pullEvent() }
        local event = res[1]
        if event == 'key_up' then
            local raw_x, raw_y, raw_z = gps.locate(GPS_TIMEOUT, false)
            local pos = {
                x = math.floor(raw_x),
                y = math.floor(raw_y),
                z = math.floor(raw_z),
            }

            local key = res[2]
            if key == keys.h then
                if #markers >= 1 and not inline(markers[#markers], pos) then
                    scroll_term('Points not inline', true)
                else
                    table.insert(markers, pos)
                    scroll_term(#markers .. ' ' .. pos.x .. ', ' .. pos.y .. ', ' .. pos.z)
                end
            elseif key == keys.f then
                pos.y = pos.y - 1
                if #markers >= 1 and not inline(markers[#markers], pos) then
                    scroll_term('Points not inline', true)
                else
                    table.insert(markers, pos)
                    scroll_term(#markers .. ' ' .. pos.x .. ', ' .. pos.y .. ', ' .. pos.z)
                end
            elseif key == keys.e and #markers > 1 then
                term.clearLine()
                local _, h = term.getSize()
                term.setCursorPos(1, h)
                write('end> ')
                local name = read()
                if #name >= 1 then
                    save_route(name, markers)
                    markers = {}
                    term.scroll(-1)
                    scroll_term('Saved to ' .. name)
                else
                    scroll_term('Empty name, not saving')
                end
            elseif key == keys.r then
                scroll_term('Reset')
                markers = {}
            end
        end
    end
end

telem:run_parallel_with('main', main)
