-- Remember to update README.md with any changes here
-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/benchmark.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('benchmark', 'See how fast stuff runs')

local function time(name, fn, iter, sub_iter)
    iter = iter or 1000
    local time_sum = 0
    if sub_iter ~= nil then
        for _ = 1, iter do
            local start = os.clock()
            for _ = 1, sub_iter do
                fn()
            end
            local stop = os.clock()
            time_sum = time_sum + (stop - start)
        end
    else
        for _ = 1, iter do
            local start = os.clock()
            fn()
            local stop = os.clock()
            time_sum = time_sum + (stop - start)
        end
    end
    local count = iter
    if sub_iter ~= nil then
        count = count + sub_iter
    end
    local cps = count / time_sum
    local hz = time_sum / count
    log:info(name, '@', cps, 'per s', hz, 'hz')
end

local function time_with_reset(name, fn, iter, reset)
    iter = iter or 1000
    local time_sum = 0
    for _ = 1, iter do
        local start = os.clock()
        fn()
        local stop = os.clock()
        reset()
        time_sum = time_sum + (stop - start)
    end
    local count = iter
    local cps = count / time_sum
    local hz = time_sum / count
    log:info(name, '@', cps, 'per s', hz, 'hz')
end

-- Main function
local function main()
    time('Detect Inventory', turtle.detect, 50)
    time('Detect Block', turtle.detectDown, 50)
    time('Detect Air', turtle.detectUp, 50)

    time('Inspect Inventory', turtle.inspect, 50)
    time('Inspect Block', turtle.inspectDown, 50)
    time('Inspect Air', turtle.inspectUp, 50)

    time_with_reset('Place Up', turtle.placeUp, 20, turtle.digUp)

    turtle.placeUp()
    time_with_reset('Dig Up', turtle.digUp, 20, turtle.placeUp)
    turtle.digUp()

    time('Dig Empty', turtle.digUp, 20)

    time('Turn', turtle.turnLeft, 20)

    time_with_reset('Up', turtle.up, 20, turtle.down)

    turtle.back()
    time_with_reset('Forward', turtle.forward, 20, turtle.back)
    turtle.forward()
end

-- Call main and log an error if raised
log:catch_errors(main)
