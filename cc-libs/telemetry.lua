local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local json = require 'cc-libs.util.json'

local TELEMETRY_PROTOCOL = 'telemetry'

---@class Telemetry
---@field location Location?
---@field modem ccTweaked.peripheral.Modem
local Telemetry = {}

---Construct a new Telemetry object
---@param location Location?
---@return Telemetry
function Telemetry:new(location)
    peripheral.find('modem', rednet.open)
    local o = {
        location = location,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Send telemetry data
---@param extra table?
function Telemetry:update_state(extra)
    local payload = {
        time_local = os.epoch('local') / 1000,
        time_utc = os.epoch('utc') / 1000,
        time_ingame = os.epoch('ingame') / 1000,
        host_id = os.getComputerID(),
        host_name = os.getComputerLabel() or '',
        -- TODO replace this with current program and other stats about it
        state = 'UNKNOWN',
        extra = extra,
    }
    if self.location then
        payload.pos, payload.heading = self.location:location()
    else
        payload.pos = gps.locate(0, false)
        payload.heading = nil
    end
    rednet.broadcast(json.encode(payload), TELEMETRY_PROTOCOL)
end

---Send telemetry event
---@param event string
---@param data table?
function Telemetry:send_event(event, data)
    local payload = {
        event = event,
        event_data = data,
        -- Metadata
        time_local = os.epoch('local') / 1000,
        time_utc = os.epoch('utc') / 1000,
        time_ingame = os.epoch('ingame') / 1000,
        host_id = os.getComputerID(),
        host_name = os.getComputerLabel() or '',
    }
    if self.location then
        payload.pos, payload.heading = self.location:location()
    else
        payload.pos = gps.locate(0, false)
        payload.heading = nil
    end
    rednet.broadcast(json.encode(payload), TELEMETRY_PROTOCOL)
end

local M = {
    Telemetry = Telemetry,
}

return M
