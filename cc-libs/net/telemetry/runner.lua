local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry.runner')

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
        event_handlers = {},
        alert_handlers = {},
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
    -- local co = coroutine.create(function()
    --     return log:wrap_call(fn, table.unpack(args))
    -- end)
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

---Register callback to handle telemetry events received over rednet
---@param event_type? string
---@param fn fun(message: EventTelemetryPayload)
---@param can_kill? boolean defaults to false
function TelemetryRunner:listen_for_event(event_type, fn, can_kill)
    if can_kill == nil then
        can_kill = false
    end
    local name = 'watch event'
    if event_type then
        name = name .. ' ' .. event_type
    end
    self:add_thread(name, can_kill, function()
        while true do
            local sender, message, protocol = rednet.receive('telemetry')
            if sender ~= nil and protocol == 'telemetry' then
                if type(message) ~= 'table' then
                    log:debug('Invalid message type received for event', type(message))
                elseif message.type == 'PAYLOAD_EVENT' and message.event then
                    log:debug('Got event', message)
                    ---@cast message EventTelemetryPayload
                    if not event_type or message.event.type == event_type then
                        pcall(fn, message)
                    end
                end
            else
                log:trace('Got invalid telemetry', sender, message, protocol)
            end
        end
    end)
end

---Register callback to handle telemetry alerts received over rednet
---@param alert_type? string
---@param fn fun(message: AlertTelemetryPayload)
---@param can_kill? boolean defaults to false
function TelemetryRunner:listen_for_alert(alert_type, fn, can_kill)
    if can_kill == nil then
        can_kill = false
    end
    local name = 'watch alert'
    if alert_type then
        name = name .. ' ' .. alert_type
    end
    self:add_thread(name, can_kill, function()
        while true do
            local sender, message, protocol = rednet.receive('telemetry')
            if sender ~= nil and protocol == 'telemetry' then
                if type(message) ~= 'table' then
                    log:debug('Invalid message type received for alert', type(message))
                elseif message.type == 'PAYLOAD_ALERT' and message.alert then
                    log:debug('Got alert', message)
                    ---@cast message AlertTelemetryPayload
                    if not alert_type or message.alert.type == alert_type then
                        pcall(fn, message)
                    end
                end
            else
                log:trace('Got invalid telemetry', sender, message, protocol)
            end
        end
    end)
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
                if not ok and param ~= 'Terminated' then
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
                    log:debug('Thread', thread.name, 'exited so all other threads will be terminated')
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
            log:debug('All threads are dead, exiting')
            self.running = false
            return true
        end

        event = table.pack(os.pullEventRaw())
    end
end

return {
    TelemetryRunner = TelemetryRunner,
}
