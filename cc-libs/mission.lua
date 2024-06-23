---@module 'ccl_logging'

local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('mission')
local cc_map = require 'cc-libs.map'
local cc_rgps = require 'cc-libs.turtle.rgps'
local cc_nav = require 'cc-libs.nav'

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

return M
