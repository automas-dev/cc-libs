package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/turtle_script.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser =
    argparse.ArgParse:new('turtle_script', 'Control a turtle with short command string and update the map server')
parser:add_arg('cmd', { help = 'command string, leave empty for repl', required = false, is_multi = true })
local args = parser:parse_args({ ... })

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_map = require 'cc-libs.map'
local Map = ccl_map.Map
local MapClient = ccl_map.MapClient

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_nav = require 'cc-libs.turtle.nav'
local Nav = ccl_nav.Nav

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local map_client = MapClient:new('server')
local map = Map:new(map_client)

local location = Location:new(map)
local tmc = Motion:new(location)
local nav = Nav:new(map, tmc)

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

local function print_help()
    local lines = 'combine commands with a space, numbers following commands will repeat them\n'
        .. 'f forward\n'
        .. 'b backward\n'
        .. 'u up\n'
        .. 'd down\n'
        .. 'l turn left\n'
        .. 'r turn right\n'
        .. 'enable enable dig\n'
        .. 'disable disable dig\n'
        .. 'm/mark add poi at current location\n'
        .. 'g/goto navigate to poi\n'
        .. '[ open loop\n'
        .. '] close loop\n'
        .. 'h/help show this message\n'
        .. 'q/quit exit the repl'
    local _, height = term.getCursorPos()
    textutils.pagedPrint(lines, height - 2)
end

local function is_valid(cmd)
    local valid = { '[', ']', 'f', 'b', 'l', 'r', 'u', 'd', 'enable', 'disable', 'm', 'mark', 'g', 'goto' }
    for _, v in ipairs(valid) do
        if cmd == v then
            return true
        end
    end
    return false
end

---Parse a command string
---@param cmd string
---@return [string, number|string][]? program
local function parse_cmd(cmd)
    -- TODO replace with str.tokenize when it works
    local all_parts = {}
    for w in cmd:gmatch('%S+') do
        table.insert(all_parts, w)
    end

    if #all_parts == 0 then
        return
    end

    log:debug('all parts are', all_parts)

    local actions = {}
    local nest = {}

    local i = 1
    while i <= #all_parts do
        local w = all_parts[i]
        if not is_valid(w) then
            log:error('Invalid command', w)
            return
        end
        if w == '[' then
            table.insert(nest, actions)
            actions = {}
        elseif w == ']' then
            if #nest == 0 then
                log:error('Unclosed [')
                return
            end
            local nest_actions = actions
            actions = table.remove(nest)
            local count = tonumber(all_parts[i + 1])
            if count == nil then
                count = 1
            else
                i = i + 1
            end
            for _ = 1, count do
                for _, v in ipairs(nest_actions) do
                    table.insert(actions, v)
                end
            end
        elseif w == 'm' or w == 'mark' then
            local name = all_parts[i + 1]
            if name == nil then
                log:error('Invalid marker name', name)
                return
            end
            table.insert(actions, { 'm', name })
            i = i + 1
        elseif w == 'g' or w == 'goto' then
            local name = all_parts[i + 1]
            if name == nil then
                log:error('Invalid marker name', name)
                return
            end
            table.insert(actions, { 'g', name })
            i = i + 1
        else
            local count = tonumber(all_parts[i + 1])
            if count == nil then
                count = 1
                while all_parts[i + 1] == w do
                    count = count + 1
                    i = i + 1
                end
            else
                i = i + 1
            end
            table.insert(actions, { w, count })
        end
        i = i + 1
    end

    return actions
end

---@param prog [string, number|string][]
local function run_prog(prog)
    for i, step in ipairs(prog) do
        local step_cmd = step[1]
        local step_arg = step[2]
        if step_cmd ~= 'q' then
            log:info('Step', i, 'is', step_cmd, step_arg)
        end
        if step_cmd == 'f' then
            ---@cast step_arg number
            if not tmc:forward(step_arg) then
                break
            end
        elseif step_cmd == 'b' then
            ---@cast step_arg number
            if not tmc:backward(step_arg) then
                break
            end
        elseif step_cmd == 'u' then
            ---@cast step_arg number
            if not tmc:up(step_arg) then
                break
            end
        elseif step_cmd == 'd' then
            ---@cast step_arg number
            if not tmc:down(step_arg) then
                break
            end
        elseif step_cmd == 'l' then
            ---@cast step_arg number
            tmc:left(step_arg)
        elseif step_cmd == 'r' then
            ---@cast step_arg number
            tmc:right(step_arg)
        elseif step_cmd == 'enable' then
            tmc:enable_dig()
        elseif step_cmd == 'disable' then
            tmc:disable_dig()
        elseif step_cmd == 'm' then
            local poi_name = step[2]
            ---@cast poi_name string
            nav:mark_poi(poi_name)
        elseif step_cmd == 'g' then
            local poi_name = step[2]
            ---@cast poi_name string
            if nav:get_poi(poi_name) == nil then
                log:warning('poi', poi_name, 'is missing')
                if map:get_waypoint(poi_name) == nil then
                    error('Missing poi ' .. tostring(poi_name))
                end
                nav:poi_from_waypoint(poi_name)
                log:info('Got poi from waypoint', poi_name)
            end
            local success, path = pcall(nav.find_path, nav, poi_name)
            if not success then
                log:error('Failed to find path to poi', poi_name)
                break
            elseif #path < 2 then
                log:error('Path is empty to poi', poi_name)
                break
            end
            nav:follow_path(path)
        else
            error('Unknown step ' .. tostring(step_cmd))
        end
    end
end

local function main()
    local prog = parse_cmd(table.concat(args.cmd, ' '))
    if prog == nil then
        error('Failed to compile program')
    end
    local success, err = pcall(run_prog, prog)
    if not success then
        log:error('Program failed', err)
    end
end

local function repl()
    while true do
        write('repl> ')
        local cmd = read()
        if cmd == 'h' or cmd == 'help' then
            print_help()
        elseif cmd == 'q' or cmd == 'quit' then
            log:info('Exiting')
            break
        elseif #cmd > 0 then
            local prog = parse_cmd(cmd)
            if prog ~= nil then
                local success, err = pcall(run_prog, prog)
                if not success then
                    log:error('Program failed', err)
                end
            end
        end
    end
end

if args.cmd ~= nil then
    telem:run_parallel_with('main', log:wrap_fn(main))
else
    telem:run_parallel_with('repl', log:wrap_fn(repl))
end
