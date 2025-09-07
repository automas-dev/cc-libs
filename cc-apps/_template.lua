-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/_template.log',
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('_template', 'Fill this in with your program')
parser:add_arg('n', { help = 'count' })
local args = parser:parse_args({ ... })

-- Import libraries
local actions = require 'cc-libs.turtle.actions'

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

-- Gather arguments
local n = args.new

-- Create objects
local tmc = Motion:new()
tmc:enable_dig()

-- Main function
local function run()
    log:info('This is just a template...', n)
end

-- Call rnu and log an error if raised
log:catch_errors(run)
