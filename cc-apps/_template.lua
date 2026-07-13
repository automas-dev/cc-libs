-- Remember to update README.md with any changes here
-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    -- TODO update log file path
    filepath = 'logs/_template.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
-- TODO update app name & description
local parser = argparse.ArgParse:new('_template', 'Fill this in with your program')
-- TODO update args and options
parser:add_arg('n', { help = 'count' })
local args = parser:parse_args({ ... })

-- Import libraries
local actions = require 'cc-libs.turtle.actions'

local ccl_location = require 'cc-libs.turtle.location'
local Location = ccl_location.Location

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

-- Gather arguments
local n = args.new

-- Create objects
local location = Location:new()
local tmc = Motion:new(location)
tmc:enable_dig()

local telem = get_telemetry()
telem:set_location(location)
tmc:attach_telemetry(telem)

-- Main function
local function main()
    log:info('This is just a template...', n)
end

-- Call main and log an error if raised
telem:run_parallel_with('main', log.catch_errors, log, main)
