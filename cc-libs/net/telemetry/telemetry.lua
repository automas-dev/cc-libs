local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local ccl_telem_runner = require 'cc-libs.net.telemetry.runner'
local TelemetryRunner = ccl_telem_runner.TelemetryRunner

local ccl_net_util = require 'cc-libs.net.util'
local open_rednet = ccl_net_util.open_rednet

local uid = require 'cc-libs.util.uid'

local TELEMETRY_PROTOCOL = 'telemetry'

local DEFAULT_HEARTBEAT_SLEEP_S = 1

---@enum PayloadType
local PayloadType = {
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
---@field fuel_level number|"unlimited"?
---@field subsystem string?
---@field state table
---@field stack string[]

---@class EventTelemetryPayload : TelemetryPayload
---@field event { id: integer, type: string, message: string, data: table? }

---@class AlertTelemetryPayload : TelemetryPayload
---@field alert { id: integer, type: string, message: string, data: table? }

---@class Telemetry
---@field subsystem string?
---@field location Location?
---@field local_state table
---@field heartbeat_sleep_s number
---@field rednet_enabled boolean
---@field stack string[]
local Telemetry = {}

---Construct a new Telemetry object
---@param subsystem? string name of subsystem sending telemetry
---@param location? Location used for position and heading metadata
---@return Telemetry
function Telemetry:new(subsystem, location)
    local o = {
        subsystem = subsystem,
        location = location,
        local_state = {},
        heartbeat_sleep_s = DEFAULT_HEARTBEAT_SLEEP_S,
        rednet_enabled = open_rednet(),
        stack = {},
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
        subsystem = self.subsystem,
        state = self.local_state,
        spans = self.stack,
    }
    if turtle then
        payload.fuel_level = turtle.getFuelLevel()
    end
    if self.location then
        payload.pos, payload.heading = self.location:location()
        payload.has_fix = self.location.has_fix
        payload.has_heading = self.location.has_heading
    else
        local x, y, z = gps.locate(0, false)
        payload.pos = { x = x, y = y, z = z }
        payload.heading = nil
        payload.has_fix = payload.pos ~= nil
        payload.has_heading = false
    end
    return payload
end

---Push new subroutine name onto stack
---@param name string subroutine name
function Telemetry:push_span(name)
    table.insert(self.stack, name)
end

---Pop the top subroutine from the stack
function Telemetry:pop_span()
    assert(#self.stack > 0)
    table.remove(self.stack)
end

---Wrap a function to label its state during execution
---@generic T : function
---@param name string
---@param fn T
---@return T
function Telemetry:span(name, fn)
    return function(...)
        log:trace('Start span', name)
        self:push_span(name)
        -- local start = os.clock()
        local res = table.pack(pcall(fn, ...))
        -- local delta = os.clock() - start
        self:pop_span()

        local success = res[1]
        if not success then
            log:error('Error in span', name, res[2])
            error(res[2], 2)
        end

        log:trace('End span', name)
        return table.unpack(res, 2)
    end
end

---Update local state included in telemetry packets
---@param state table
function Telemetry:update_state(state)
    for k, v in pairs(state) do
        self.local_state[k] = v
    end
end

---Send telemetry event
---@param event_type string
---@param msg string
---@param data? table
---@return EventTelemetryPayload payload
function Telemetry:send_event(event_type, msg, data)
    local payload = self:_build_payload(PayloadType.EVENT)
    ---@cast payload EventTelemetryPayload
    if self.subsystem ~= nil then
        event_type = self.subsystem .. '.' .. event_type
    end
    payload.event = {
        id = uid(),
        type = event_type,
        message = msg,
        data = data,
    }
    if self.rednet_enabled then
        -- local message = json.encode(payload)
        local message = payload
        rednet.broadcast(message, TELEMETRY_PROTOCOL)
        log:trace('Sent event to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    end
    return payload
end

---Send telemetry event
---@param alert_type string
---@param msg string
---@param data? table
---@return AlertTelemetryPayload payload
function Telemetry:send_alert(alert_type, msg, data)
    local payload = self:_build_payload(PayloadType.ALERT)
    ---@cast payload AlertTelemetryPayload
    if self.subsystem ~= nil then
        alert_type = self.subsystem .. '.' .. alert_type
    end
    payload.alert = {
        id = uid(),
        type = alert_type,
        message = msg,
        data = data,
    }
    if self.rednet_enabled then
        -- local message = json.encode(payload)
        local message = payload
        rednet.broadcast(message, TELEMETRY_PROTOCOL)
        log:trace('Sent alert to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    end
    return payload
end

---Get TelemetryRunner
---@return TelemetryRunner runner
function Telemetry:make_runner()
    local runner = TelemetryRunner:new(self)

    local function run_heartbeat_thread()
        while true do
            log:wrap_call(self.send_event, self, 'heartbeat', 'Heartbeat')
            -- in game time is 72 times faster, epoch is in ms
            local next = os.clock() + self.heartbeat_sleep_s
            log:trace('Next hb at', next)
            -- os.sleep can get stuck if the timer event is missed.
            while os.clock() < next do
                os.pullEvent()
            end
        end
    end
    runner:add_thread('heartbeat', false, log:wrap_fn(run_heartbeat_thread))

    return runner
end

---Run fn in parallel with telemetry thread
---@param fn fun(...):... function to run
---@param ... any args to the function
---@return boolean success no errors occurred during execution
---@return any ... the result from fn
function Telemetry:run_parallel_with(name, fn, ...)
    local args = { ... }
    local result = nil

    -- This function captures the result from the call to fn
    local function run_fn()
        result = fn(table.unpack(args))
    end

    local runner = self:make_runner()
    runner:add_thread(name, true, run_fn)

    local success = runner:run()
    return success, result
end

local M = {
    Telemetry = Telemetry,
    TELEMETRY_PROTOCOL = TELEMETRY_PROTOCOL,
    PayloadType = PayloadType,
    ---@type { [string]: Telemetry }
    subsystems = {},
}

---Get the global or subsystem telemetry object
---@param subsystem? string name of a subsystem
---@param location? Location location used to create Telemetry if subsystem does not exist
---@return Telemetry
function M.get_telemetry(subsystem, location)
    local subsystem_key = subsystem or '_'
    local is_root = subsystem == nil
    local telem = M.subsystems[subsystem_key]

    -- Create Telemetry for subsystem if one does not already exist
    if telem == nil then
        log:debug('Creating telemetry for subsystem', subsystem)
        telem = Telemetry:new(subsystem, location)
        M.subsystems[subsystem_key] = telem
    end

    local root = M.subsystems['_']

    if is_root then
        if root.location ~= nil then
            -- For all subsystems missing location, copy root location
            log:trace('Copying root location to existing subsystems')
            for s, sub in pairs(M.subsystems) do
                local sub_is_root = s ~= '_'
                -- Only update not root subsystems that are missing location
                if not sub_is_root and sub.location == nil then
                    log:trace('Using root location for subsystem', s)
                    sub.location = root.location
                end
            end
        end
    elseif telem.location == nil then
        -- Update location if missing
        if location ~= nil then
            log:trace('Adding location to subsystem', subsystem)
            telem.location = location
        elseif root ~= nil and root.location ~= nil then
            log:trace('Adding root location to subsystem', subsystem)
            telem.location = root.location
        end
    end

    return telem
end

return M
