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
parser:add_option('f', 'file', 'script file to read and run', true)
local args = parser:parse_args({ ... })

local ccl_ts = require 'cc-libs.turtle.script'
local TSContext = ccl_ts.TSContext

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

local context = TSContext:new(tmc, nav)

context:register_math()
context:register_turtle()
-- context:register('face', true, function(_, _, dir)
--     if dir ~= 'front' and dir ~= 'back' and dir ~= 'left' and dir ~= 'right' then
--         return false
--     end
--     return true
-- end)

local function main()
    local text
    if args.file ~= nil then
        log:info('Loading script from', args.file)
        local file = assert(io.open(args.file, 'r'))
        text = file:read('a')
        file:close()
    else
        text = table.concat(args.cmd, ' ')
    end
    local success, err = context:exec(text)
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
            table.insert(history, cmd)
            log:trace('History now', history)
            local success, err = context:exec(cmd)
            if not success then
                log:error('Program failed', err)
            end
        end
    end
end

if args.cmd ~= nil or args.file ~= nil then
    telem:run_parallel_with('main', log:wrap_fn(main))
else
    telem:run_parallel_with('repl', log:wrap_fn(repl))
end
