-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/portal_takedown.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local tmc = Motion:new()
tmc:enable_dig()

-- 9 7 6 5
-- 8     4
-- a     3
-- b     1 start
-- c d e 2

local function run()
    -- 1
    tmc:forward()
    -- 2
    turtle.digDown()
    -- 3, 4
    tmc:up(2)
    -- 5
    turtle.digUp()
    -- 6
    tmc:forward()
    turtle.digUp()
    -- 7
    tmc:forward()
    turtle.digUp()
    -- 8
    tmc:forward()
    -- 9
    turtle.digUp()
    -- a
    tmc:down()
    -- b
    tmc:down()
    -- c
    tmc:down()
    -- d, e
    tmc:around()
    tmc:forward(3)
    -- return
    tmc:up()
    tmc:forward()
    tmc:around()
end

-- Call rnu and log an error if raised
log:catch_errors(run)
