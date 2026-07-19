-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/dig_down.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('dig_down', 'Dig a vertical shaft straight down')
parser:add_arg('n', { help = 'number of blocks to mine down' })
local args = parser:parse_args({ ... })

local n = tonumber(args.n)

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    error('Not enough fuel! Need ' .. tostring(fuel_need))
end

local tmc = ccl_motion.Motion:new()
tmc:enable_dig()

local function main()
    local total = 0
    for _ = 1, n do
        if not tmc:down() then
            break
        end
        total = total + 1
    end

    -- Return

    log:info('Returning to station')

    for _ = 1, total do
        tmc:up()
    end

    log:info('Done!')
end

log:catch_errors(main)
