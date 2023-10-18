local serialize = require 'cc-libs.serialize'
local logging = require 'cc-libs.logging'
local log = logging:new('map')
logging.MAP = log

local M = {}

function M:new()
    local o = {
        graph={},
        waypoints={},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function M:load(path)
    log:debug('Dumping map to', path)

    local file = assert(io.open(path, 'r'))
    local data = file:read('*all')
    file:close()
    self.graph = data.graph
    self.waypoints = data.waypoints
end

function M:dump(path)
    log:debug('Loading map from', path)

    local file = assert(io.open(path, 'w'))
    file:write(serialize.dump(self))
    file:close()
end

local function is_inline(pos1, pos2)
    if pos1.x ~= pos2.x then
        return pos1.y == pos2.y and pos1.z == pos2.z
    elseif pos1.y ~= pos2.y then
        return pos1.x == pos2.x and pos1.z == pos2.z
    elseif pos1.z ~= pos2.z then
        return pos1.x == pos2.x and pos1.y == pos2.y
    else
        return true
    end
end

function M:connect(p1, p2)
    assert(is_inline(p1, p2), 'p1 is not inline with p2')

    self.graph[p1] = p2
end

return M
