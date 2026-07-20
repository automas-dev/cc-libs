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

local ccl_ts = require 'cc-libs.turtle.script'
local TSLexer = ccl_ts.TSLexer
local TSParser = ccl_ts.TSParser
local TSTokenType = ccl_ts.TSTokenType

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

---@type { [string]: TSToken[] }
local fn_def = {}

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

---Parse a command string
---@param cmd string
---@return TSToken[] program
local function parse_cmd(cmd)
    local ts_lexer = TSLexer:new(cmd)
    local ts_parser = TSParser:new(ts_lexer)
    ts_parser:takes_arg('m')
    ts_parser:takes_arg('mark')
    ts_parser:takes_arg('g')
    ts_parser:takes_arg('goto')
    local prog = ts_parser:parse()
    return prog
end

---@param prog TSToken[]
---@param active_fn_stack string[]
---@return boolean success
local function run_prog(prog, active_fn_stack)
    if active_fn_stack == nil then
        active_fn_stack = {}
    end
    log:debug('function stack is', active_fn_stack)
    for i, step in ipairs(prog) do
        if step.type == TSTokenType.DEF then
            fn_def[step.name] = step.children
        end
        if step.type == TSTokenType.LOOP then
            for _ = 1, step.count do
                if not run_prog(step.children, active_fn_stack) then
                    return false
                end
            end
        end
        if step.type == TSTokenType.CALL then
            for _, s in ipairs(active_fn_stack) do
                if s == step.name then
                    error(
                        'Recursion detected in function '
                            .. tostring(active_fn_stack[#active_fn_stack])
                            .. ' when calling '
                            .. tostring(step.name)
                    )
                end
            end
            if step.name ~= 'q' then
                log:info('Step', i, 'is', step.name, step.arg, step.count)
            end
            if fn_def[step.name] ~= nil then
                log:debug('call fn', step.name)
                table.insert(active_fn_stack, step.name)
                local len_before = #active_fn_stack
                if not run_prog(fn_def[step.name], active_fn_stack) then
                    return false
                end
                assert(#active_fn_stack == len_before, 'Unbalanced function stack')
                table.remove(active_fn_stack)
            elseif step.name == 'f' then
                if not tmc:forward(step.count) then
                    return false
                end
            elseif step.name == 'b' then
                if not tmc:backward(step.count) then
                    return false
                end
            elseif step.name == 'u' then
                if not tmc:up(step.count) then
                    return false
                end
            elseif step.name == 'd' then
                if not tmc:down(step.count) then
                    return false
                end
            elseif step.name == 'l' then
                tmc:left(step.count)
            elseif step.name == 'r' then
                tmc:right(step.count)
            elseif step.name == 'enable' then
                tmc:enable_dig()
            elseif step.name == 'disable' then
                tmc:disable_dig()
            elseif step.name == 'm' or step.name == 'mark' then
                local poi_name = step.arg
                assert(poi_name ~= nil)
                nav:mark_poi(poi_name)
            elseif step.name == 'g' or step.name == 'goto' then
                local poi_name = step.arg
                assert(poi_name ~= nil)
                if nav:get_poi(poi_name) == nil then
                    log:warning('poi', poi_name, 'is missing')
                    if nav.map:get_waypoint(poi_name) == nil then
                        error('Missing poi ' .. tostring(poi_name))
                    end
                    nav:poi_from_waypoint(poi_name)
                    log:info('Got poi from waypoint', poi_name)
                end
                local success, path = pcall(nav.find_path, nav, poi_name)
                if not success then
                    log:error('Failed to find path to poi', poi_name)
                    return false
                elseif #path < 2 then
                    log:error('Path is empty to poi', poi_name)
                    return false
                end
                nav:follow_path(path)
            else
                error('Unknown step ' .. tostring(step.name))
            end
        end
    end
    return true
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
    local history = {}
    while true do
        write('repl> ')
        local cmd = read(nil, history)
        if cmd == 'h' or cmd == 'help' then
            print_help()
        elseif cmd == 'q' or cmd == 'quit' then
            log:info('Exiting')
            break
        elseif #cmd > 0 then
            local prog = parse_cmd(cmd)
            if prog ~= nil then
                table.insert(history, cmd)
                log:trace('History now', history)
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
