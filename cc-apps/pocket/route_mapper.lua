package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.ERROR,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/pocket_route_mapper.log',
}

local ccl_map = require 'cc-libs.map'
local MapClient = ccl_map.MapClient

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

---Check if another point is inline with one of this points axis (ie. 2 axes match)
---@param a { x: number, y: number, z:number }
---@param b { x: number, y: number, z:number }
---@return boolean
local function inline(a, b)
    if a.x ~= b.x then
        return a.y == b.y and a.z == b.z
    elseif a.y ~= b.y then
        return a.z == b.z
    else
        return true
    end
end

local function print_toolbar()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    local _, h = term.getSize()
    -- Clear the toolbar line and move cursor to the start
    term.setCursorPos(0, h)
    term.clearLine()
    -- Print toolbar
    print('h - mark head; f - mark foot; e - end; r - reset;')
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
    term.setCursorPos(0, h)
    term.clearLine()
    -- Print lines
    term.setBackgroundColor(colors.black)
    term.setBackgroundColor(error and colors.red or colors.lightGray)
    print(line)
    -- Scroll lines
    term.scroll(1)
    -- Print toolbar
    print_toolbar()
end

local function save_route(name, markers)
    -- TODO clear points between each set of markers
    -- TODO mask points between each set of markers
    -- TODO directional link between markers
end

local function main()
    client = MapClient:new('server')

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
                if #markers > 1 then
                    if not (inline(markers[#markers], pos)) then
                        scroll_term('Points not inline', true)
                    end
                end
                table.insert(markers, pos)
                scroll_term('Marker at head ' .. pos.x .. ', ' .. pos.y .. ', ' .. pos.z)
            elseif key == keys.f then
                y = y - 1
                if #markers > 1 then
                    if not (inline(markers[#markers], pos)) then
                        scroll_term('Points not inline', true)
                    end
                end
                table.insert(markers, pos)
                scroll_term('Marker at feet ' .. pos.x .. ', ' .. pos.y .. ', ' .. pos.z)
            elseif key == keys.e then
                term.clearLine()
                print('End')
                write('> ')
                local name = read()
                if name then
                    save_route(name, markers)
                    markers = {}
                    clear_term()
                else
                    scroll_term('Empty name, route not saved')
                end
            elseif key == keys.r then
                scroll_term('Reset')
                markers = {}
            end
        end
    end
end

telem:run_parallel_with('main', main)
