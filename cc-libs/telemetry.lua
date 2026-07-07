local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local json = require 'cc-libs.util.json'

local uuid = require 'cc-libs.util.uuid'

local TELEMETRY_PROTOCOL = 'telemetry'

---@enum PayloadType
local PayloadType = {
    STATE = 1,
    EVENT = 2,
}

---@class Telemetry
---@field location Location?
---@field telemetry_sleep_s number
local Telemetry = {}

---Construct a new Telemetry object
---@param location Location?
---@return Telemetry
function Telemetry:new(location)
    peripheral.find('modem', rednet.open)
    local o = {
        location = location,
        telemetry_sleep_s = 1,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Build a payload packet with common fields
---@private
---@param type PayloadType
---@return table payload the payload table with common fields
function Telemetry:_build_payload(type)
    local payload = {
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
---@param extra table?
---@return table payload
function Telemetry:update_state(extra)
    local payload = self:_build_payload(PayloadType.STATE)
    -- TODO replace this with current program and other stats about it
    payload.state = 'UNKNOWN'
    payload.extra = extra
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent state to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    return payload
end

---Send telemetry event
---@param event string
---@param data table?
---@return table payload
function Telemetry:send_event(event, data)
    local payload = self:_build_payload(PayloadType.EVENT)
    payload.event_id = uuid()
    payload.event = event
    payload.event_data = data
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent event to protocol', TELEMETRY_PROTOCOL, 'with message', message)
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
    local function run_telem()
        while true do
            self:update_state()
            os.sleep(self.telemetry_sleep_s)
        end
    end
    parallel.waitForAny(run_fn, run_telem)
    return result
end

local M = {
    Telemetry = Telemetry,
}

return M
