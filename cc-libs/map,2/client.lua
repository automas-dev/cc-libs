local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('map')

local json = require 'cc-libs.util.json'

---@class MapClient
---@field map Map
local MapClient = {}

---Create a new Server object
---@param map Map
---@return MapClient
function MapClient:new(map)
    local o = {
        map = map,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

return {
    MapClient = MapClient,
}
