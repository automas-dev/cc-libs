local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local json = require 'cc-libs.util.json'

local uuid = require 'cc-libs.util.uuid'

local TELEMETRY_PROTOCOL = 'telemetry'

---@enum PayloadType
local PayloadType = {
    ---Payload with `state` field
    STATE = 'PAYLOAD_STATE',
    ---Payload with `event` field
    EVENT = 'PAYLOAD_EVENT',
    ---Payload with `alert` field
    ALERT = 'PAYLOAD_ALERT',
}

---@class TelemetryPayload
---@field _telem_type PayloadType
---@field type PayloadType
---@field time_local number
---@field time_utc number
---@field time_ingame number
---@field host_id number
---@field host_name string
---@field pos? Vec3
---@field heading? number
---@field has_fix boolean
---@field has_heading boolean

---@class StateTelemetryPayload : TelemetryPayload
---@field state? table

---@class EventTelemetryPayload : TelemetryPayload
---@field event { id: string, type: string, message: string, data: table? }

---@class AlertTelemetryPayload : TelemetryPayload
---@field alert { id: string, type: string, message: string, data: table? }

---@class Telemetry
---@field location Location?
---@field telemetry_sleep_s number
---@field os_events_enabled boolean
local Telemetry = {}

---Construct a new Telemetry object
---@param location? Location used for position and heading metadata
---@return Telemetry
function Telemetry:new(location)
    peripheral.find('modem', rednet.open)
    local o = {
        location = location,
        telemetry_sleep_s = 1,
        os_events_enabled = true,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Set the Location instance for telemetry data
---@param location Location
function Telemetry:set_location(location)
    self.location = location
end

---Build a payload packet with common fields
---@private
---@param type PayloadType
---@return TelemetryPayload payload the payload table with common fields
function Telemetry:_build_payload(type)
    local payload = {
        _telem_type = type,
        type = type,
        time_local = os.epoch('local') / 1000,
        time_utc = os.epoch('utc') / 1000,
        time_ingame = os.epoch('ingame') / 1000,
        host_id = os.getComputerID(),
        host_name = os.getComputerLabel() or '',
    }
    if self.location then
        payload.pos, payload.heading = self.location:location()
        payload.has_fix = self.location.has_fix
        payload.has_heading = self.location.has_heading
    else
        payload.pos = gps.locate(0, false)
        payload.heading = nil
        payload.has_fix = payload.pos ~= nil
        payload.has_heading = false
    end
    return payload
end

---Send telemetry data
---@param state? table
---@return StateTelemetryPayload payload
function Telemetry:update_state(state)
    local payload = self:_build_payload(PayloadType.STATE)
    ---@cast payload StateTelemetryPayload
    -- TODO replace this with current program and other stats about it
    payload.state = state
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent state to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    return payload
end

---Send telemetry event
---@param type string
---@param msg string
---@param data? table
---@return EventTelemetryPayload payload
function Telemetry:send_event(type, msg, data)
    local payload = self:_build_payload(PayloadType.EVENT)
    ---@cast payload EventTelemetryPayload
    payload.event = {
        id = uuid(),
        type = type,
        message = msg,
        data = data,
    }
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent event to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    return payload
end

---Send telemetry event
---@param type string
---@param msg string
---@param data? table
---@return AlertTelemetryPayload payload
function Telemetry:send_alert(type, msg, data)
    local payload = self:_build_payload(PayloadType.ALERT)
    ---@cast payload AlertTelemetryPayload
    payload.alert = {
        id = uuid(),
        type = type,
        message = msg,
        data = data,
    }
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent alert to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    return payload
end

---Run fn in parallel with telemetry thread
---@param fn fun(...):... function to run
---@param ... any args to the function
---@return any ... the result from fn
function Telemetry:run_parallel_with(fn, ...)
    local args = { ... }
    local result = nil
    local function run_fn()
        result = fn(table.unpack(args))
    end
    local function run_state_thread()
        while true do
            self:update_state()
            os.sleep(self.telemetry_sleep_s)
        end
    end
    local function run_event_thread()
        while true do
            local event_data = { os.pullEvent() }
            self:send_event('os_event', 'Received OS event ' .. event_data[1], event_data)
        end
    end

    if self.os_events_enabled then
        parallel.waitForAny(run_fn, run_state_thread, run_event_thread)
    else
        parallel.waitForAny(run_fn, run_state_thread)
    end

    return result
end

local M = {
    Telemetry = Telemetry,
    TELEMETRY_PROTOCOL = TELEMETRY_PROTOCOL,
    PayloadType = PayloadType,
}

local _telem = nil

---Get the global telemetry object
---@return Telemetry
function M.get_telemetry()
    if not _telem then
        _telem = Telemetry:new()
    end
    return _telem
end

return M
