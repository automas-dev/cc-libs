package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/lumber.log',
}
local log = logging.get_logger('main')

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local tmc = Motion:new()
tmc:enable_dig()

local function is_log()
    local exists, info = turtle.inspect()
    if exists then
        local name = info.name
        return string.find(name, 'log') ~= nil
    end
    return false
end

local function harvest()
    log:info('Starting harvest')
    local height = 0
    while is_log() do
        log:trace('Mining log at height', height)
        turtle.dig()
        tmc:up()
        height = height + 1
    end
    log:info('Finished mining', height, 'logs')
    tmc:down(height)
end

local function run()
    while true do
        if is_log() then
            harvest()
        end
        sleep(1)
    end
end

log:catch_errors(run)
