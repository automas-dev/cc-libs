-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/stairs.log',
}
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'

local argparse = require 'cc-libs.util.argparse'
local parser =
    argparse.ArgParse:new('stairs', 'Mine a staircase down optionally placing stairs from slot 1 on the return')
parser:add_arg('n', { help = 'number of steps' })
parser:add_option('p', 'place_stairs', 'place stairs from slot 1 on the return')
local args = parser:parse_args({ ... })

local n = tonumber(args.n)
local place_stairs = args.place_stairs

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 4 * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    log:fatal('Not enough fuel! Need', fuel_need)
end

turtle.select(1)
if place_stairs and turtle.getItemCount(1) < n then
    log:fatal('Not enough stairs in slot 1, need', n)
end

local tmc = ccl_motion.Motion:new()
tmc:enable_dig()

local function main()
    tmc:up()

    for i = 1, n do
        if turtle.getFuelLevel() == 0 then
            log:fatal('Ran out of fuel!')
        end

        tmc:forward()
        turtle.digUp()

        if place_stairs and i % 2 == 1 then
            tmc:up()
            turtle.digUp()
            if i < n then
                turtle.dig()
            end
            tmc:down()
        end

        tmc:down()
        turtle.digDown()
    end

    -- Return

    log:info('Returning to station')

    tmc:around()

    for _ = 1, n do
        if place_stairs then
            turtle.placeDown()
        end
        tmc:up()
        tmc:forward()
    end

    tmc:around()
    tmc:down()

    log:info('Done!')
end

log:catch_errors(main)
