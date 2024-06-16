local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('stats')

local M = {}

function M:new()
    local o = {
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:check_fuel(fuel_need)
    assert(type(fuel_need) == 'number', 'fuel_need must be a number')
    log:info('Starting fuel level', turtle.getFuelLevel())
    log:info('Fuel needed is', fuel_need)
    if turtle.getFuelLevel() < fuel_need then
        log:error('Not enough fuel! Need', fuel_need)
        return false
    end
    return true
end

return M
