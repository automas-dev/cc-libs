local vec = require 'cc-libs.util.vec'
local Vec3 = vec.Vec3

---@class Record
---@field subsystem string
---@field level number|LogLevel
---@field location string
---@field message string
---@field time number
---@field host_id number
---@field host_name string
---@field gps Vec3?
local Record = {}

---Create a new Record instance
---@param subsystem string
---@param level number|LogLevel
---@param location string
---@param message string
---@return Record
function Record:new(subsystem, level, location, message, time)
    local o = {
        subsystem = subsystem,
        level = level,
        location = location,
        message = message,
        time = time,
        -- luacheck: push ignore 143
        host_id = os.getComputerID(),
        host_name = os.getComputerLabel() or '',
        --luacheck: pop
    }
    if gps and gps.locate then
        local x, y, z = gps.locate(0, false)
        if x ~= nil then
            o.gps = Vec3:new(x, y, z)
        end
    end
    setmetatable(o, self)
    self.__index = self
    return o
end

return {
    Record = Record,
}
