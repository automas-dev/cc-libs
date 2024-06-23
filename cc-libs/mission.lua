---@module 'ccl_logging'
local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('mission')
local cc_map = require('cc-libs.map')
local cc_rgps = require('cc-libs.rgps')
local cc_nav = require('cc-libs.nav')

local FORWARD_MAX_TRIES = 10

local M = {}

function M:new(map)
    log:trace('New mission instance')
    map = map or cc_map:new()
    local gps = cc_rgps:new(map)
    local nav = cc_nav:new(gps, map)
    local o = {
        gps = gps,
        nav = nav,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:try_forward(n, max_tries)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    max_tries = max_tries or FORWARD_MAX_TRIES
    assert(max_tries >= 0, 'max_tries must be positive')

    for _ = 1, n do
        local did_move = false
        for _ = 1, max_tries do
            if self.gps:forward() then
                did_move = true
                break
            else
                log:debug('Could not move forward, trying to dig')
                turtle.dig()
            end
        end

        if not did_move then
            log:fatal('Failed to move forward after', max_tries, 'attempts')
            return false
        end
    end

    return true
end

function M:dig_forward(n, max_tries)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    max_tries = max_tries or FORWARD_MAX_TRIES
    assert(max_tries >= 0, 'max_tries must be positive')

    for _ = 1, n do
        if turtle.getFuelLevel() == 0 then
            log:fatal('Ran out of fuel!')
            return false
        end

        turtle.dig()
        if not M:try_forward(1, max_tries) then
            return false
        end
        turtle.digUp()

        local has_block, data = turtle.inspectDown()
        if has_block then
            if data.name ~= 'minecraft:torch' then
                turtle.digDown()
            end
        end
    end

    return true
end

return M
