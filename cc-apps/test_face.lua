-- Remember to update README.md with any changes here
-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/test_face.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_location = require 'cc-libs.turtle.location'
local Compass = ccl_location.Compass

-- Create objects
local tmc = Motion:new()

-- Main function
local function main()
    -- Get heading fix
    tmc:forward()
    tmc:backward()

    -- Turn right by 1
    tmc:face(Compass.EAST)
    sleep(1)
    tmc:face(Compass.SOUTH)
    sleep(1)
    tmc:face(Compass.WEST)
    sleep(1)
    tmc:face(Compass.NORTH)
    sleep(1)

    -- Turn left by 1
    tmc:face(Compass.WEST)
    sleep(1)
    tmc:face(Compass.SOUTH)
    sleep(1)
    tmc:face(Compass.EAST)
    sleep(1)
    tmc:face(Compass.NORTH)
    sleep(1)

    -- Turn around
    tmc:face(Compass.SOUTH)
    sleep(1)
    tmc:face(Compass.NORTH)
    sleep(1)

    tmc:face(Compass.EAST)
    sleep(1)

    -- Turn around
    tmc:face(Compass.WEST)
    sleep(1)
    tmc:face(Compass.EAST)
    sleep(1)

    tmc:face(Compass.NORTH)
end

-- Call main and log an error if raised
log:catch_errors(main)
