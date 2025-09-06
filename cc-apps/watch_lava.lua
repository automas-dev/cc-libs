-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.TRACE,
    filepath = 'logs/watch_lava.log',
}
local log = logging.get_logger('main')

local function get_block_name()
    local exists, data = turtle.inspect()
    if exists then
        local block_name = data['name']
        return block_name
    end
    return nil
end

local function run()
    local last_name = nil
    while true do
        local name = get_block_name()
        if name ~= last_name then
            log:info('New block name', name)
            last_name = name
        end
        log:trace('Sleeping until next check')
        sleep(1)
    end
end

log:log_errors(run)
