local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local json = require 'cc-libs.util.json'

local uuid = require 'cc-libs.util.uuid'

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
---@field subsystem string?
---@field state table
---@field stack string[]

---@class EventTelemetryPayload : TelemetryPayload
---@field event { id: string, type: string, message: string, data: table? }

---@class AlertTelemetryPayload : TelemetryPayload
---@field alert { id: string, type: string, message: string, data: table? }

---@class Telemetry
---@field subsystem string?
---@field location Location?
---@field local_state table
---@field heartbeat_sleep_s number
---@field subroutine_stack string[]
local Telemetry = {}

---Construct a new Telemetry object
---@param subsystem? string name of subsystem sending telemetry
---@param location? Location used for position and heading metadata
---@return Telemetry
function Telemetry:new(subsystem, location)
    peripheral.find('modem', rednet.open)
    local o = {
        subsystem = subsystem,
        location = location,
        local_state = {},
        heartbeat_sleep_s = DEFAULT_HEARTBEAT_SLEEP_S,
        subroutine_stack = {},
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
        stack = self.subroutine_stack,
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

---Push new subroutine name onto stack
---@param name string subroutine name
function Telemetry:push_subroutine(name)
    table.insert(self.subroutine_stack, name)
end

---Pop the top subroutine from the stack
function Telemetry:pop_subroutine()
    if #self.subroutine_stack > 0 then
        table.remove(self.subroutine_stack)
    end
end

---Wrap a function to label it's state during execution
---@generic T : function
---@param name string
---@param fn T
---@return T
function Telemetry:make_routine(name, fn)
    return function(...)
        log:debug('Start routine', name)
        self:push_subroutine(name)
        local res = table.pack(pcall(fn, ...))
        self:pop_subroutine()

        local success = res[1]
        if not success then
            log:error('Error in routine', name, res[2])
            error(res[2], 2)
        end

        log:debug('End routine', name)
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
        id = uuid(),
        type = event_type,
        message = msg,
        data = data,
    }
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent event to protocol', TELEMETRY_PROTOCOL, 'with message', message)
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
        id = uuid(),
        type = alert_type,
        message = msg,
        data = data,
    }
    local message = json.encode(payload)
    rednet.broadcast(message, TELEMETRY_PROTOCOL)
    log:trace('Sent alert to protocol', TELEMETRY_PROTOCOL, 'with message', message)
    return payload
end

---Thread manager with telemetry broadcast
---@class TelemetryRunner
---@field telem Telemetry
---@field running boolean
---@field private threads { name: string, can_kill: boolean, co: thread, filter: string? }[]
local TelemetryRunner = {}

---@return TelemetryRunner
---@param telem Telemetry
function TelemetryRunner:new(telem)
    local o = {
        telem = telem,
        running = false,
        threads = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Add a new thread to the runner
---@param name string name of the thread used in telemetry
---@param can_kill boolean if this process exists, kill the rest
---@param fn function thread function
---@param ... any arguments passed to `fn`
---@return boolean success
function TelemetryRunner:add_thread(name, can_kill, fn, ...)
    if self.running then
        log:warning('Tried to add thread', name, 'while running')
        return false
    end

    local args = { ... }
    local co = coroutine.create(function()
        return fn(table.unpack(args))
    end)
    table.insert(self.threads, {
        name = name,
        can_kill = can_kill,
        co = co,
        filter = nil,
    })
    return true
end

function TelemetryRunner:terminate_all()
    log:debug('Terminating all threads')
    self.telem:send_event('runner.terminate_all', 'Terminating ' .. #self.threads .. ' threads')

    local did_kill = 0
    for _, thread in ipairs(self.threads) do
        if coroutine.status(thread.co) ~= 'dead' then
            log:debug('Thread', thread.name, 'is alive, sending terminate')
            coroutine.resume(thread.co, 'terminate')
            did_kill = did_kill + 1
        else
            log:trace('Thread', thread.name, 'is already dead')
        end
    end

    log:debug('Finished terminating', did_kill, 'threads')
end

---Run all threads to completion
---@return boolean success
---@return string? err
function TelemetryRunner:run()
    if self.running then
        log:warning('Tried to start TelemetryRunner twice')
        return false, 'already running'
    end

    log:debug('Starting telemetry runner with', #self.threads, 'threads')
    if #self.threads == 0 then
        log:debug('No threads, exiting early')
        return true
    end

    -- Modified version of parallel.waitForAny and parallel.waitForAll

    self.running = true

    -- Start with empty event to launch all threads
    local event = { n = 0 }
    while true do
        for _, thread in ipairs(self.threads) do
            if thread.filter == nil or thread.filter == event[1] or event[1] == 'terminate' then
                local ok, param = coroutine.resume(thread.co, table.unpack(event, 1, event.n))
                if not ok then
                    log:warning('Thread', thread.name, 'failed with', param)
                    self.telem:send_alert(
                        'runner.thread_error',
                        'Thread ' .. thread.name .. ' failed',
                        { name = thread.name, can_kill = thread.can_kill, filter = thread.filter, param = param }
                    )
                    if thread.can_kill then
                        self:terminate_all()
                        self.running = false
                        return false, 'error in thread ' .. thread.name
                    end
                end

                if coroutine.status(thread.co) == 'dead' then
                    log:debug('Thread', thread.name, 'died')
                    self.telem:send_event(
                        'runner.thread_died',
                        'Thread ' .. thread.name .. ' died',
                        { name = thread.name, can_kill = thread.can_kill }
                    )
                end

                thread.filter = param
            end
        end

        local i = 1
        while i <= #self.threads do
            local thread = self.threads[i]
            if coroutine.status(thread.co) == 'dead' then
                if thread.can_kill then
                    log:info('Thread', thread.name, 'exited so all other threads will be terminated')
                    self:terminate_all()
                    self.running = false
                    return true
                end

                log:debug('Removing dead thread', thread.name)
                table.remove(self.threads, i)
            else
                i = i + 1
            end
        end

        if #self.threads == 0 then
            log:info('All threads are dead, exiting')
            self.running = false
            return true
        end

        event = table.pack(os.pullEventRaw())
    end
end

---Get TelemetryRunner
---@return TelemetryRunner runner
function Telemetry:make_runner()
    local runner = TelemetryRunner:new(self)
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

    local function run_fn()
        result = fn(table.unpack(args))
    end

    local runner = self:make_runner()
    runner:add_thread(name, true, run_fn)

    local function run_heartbeat_thread()
        while true do
            self:send_event('heartbeat', 'Heartbeat')
            os.sleep(self.heartbeat_sleep_s)
        end
    end
    runner:add_thread('heartbeat', false, run_heartbeat_thread)

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
