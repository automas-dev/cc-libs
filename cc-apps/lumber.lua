-- Remember to update README.md with any changes here
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

local function place_sapling()
    for i = 1, 16 do
        local item = turtle.getItemDetail(i)
        log:trace('Checking slot', i, 'found item', item)
        if item ~= nil and string.find(item.name, 'sapling') ~= nil then
            log:info('Placing sapling', item.name, 'from slot', i)
            turtle.select(i)
            turtle.place()
            return true
        end
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

local function main()
    log:info('Starting lumber, waiting for logs')
    while true do
        if is_log() then
            harvest()
            if not place_sapling() then
                log:info('Did not place a sapling so the program will exit')
                return
            end
        end
        sleep(1)
    end
end

log:catch_errors(main)
