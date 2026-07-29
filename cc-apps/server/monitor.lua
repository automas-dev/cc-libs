package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/server_monitor.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry
local PayloadType = ccl_telemetry.PayloadType

local telem = get_telemetry()
local runner = telem:make_runner()

local HB_TIMEOUT_s = 10

local monitor = peripheral.find('monitor')
if not monitor then
    log:error('Failed to find monitor peripheral')
    return
end
monitor.setTextScale(0.5)

local function clear_term()
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)
    monitor.clear()
    monitor.setCursorPos(1, 1)
    monitor.setCursorBlink(false)
end

---@type { [integer]: number }
local last_seen = {}

---@type { [integer] : EventTelemetryPayload }
local watch = {}

---@type { [integer] : EventTelemetryPayload[] }
local events = {}

---@type { [integer] : AlertTelemetryPayload[] }
local alerts = {}

local function update_term()
    clear_term()
    local keys = {}
    for id in pairs(watch) do
        table.insert(keys, id)
    end
    table.sort(keys)
    local now = os.clock()
    for i, id in ipairs(keys) do
        monitor.setCursorPos(1, i)
        local msg = watch[id]
        local id_events = events[id] or {}
        local id_alerts = alerts[id] or {}
        if (last_seen[id] or 0) + HB_TIMEOUT_s < now then
            monitor.setTextColor(colors.red)
        else
            monitor.setTextColor(colors.green)
        end
        monitor.write(id)
        monitor.setTextColor(colors.white)
        -- write(':' .. msg.host_name .. ' ' .. math.floor(msg.time_ingame) .. ' (')
        monitor.write(':' .. msg.host_name .. ' (')
        if msg.pos then
            monitor.write(math.floor(msg.pos.x) .. ',' .. math.floor(msg.pos.y) .. ',' .. math.floor(msg.pos.z) .. ',')
        end
        if msg.has_fix then
            monitor.write('f,')
        end
        if msg.has_fix then
            monitor.write('h')
        end
        monitor.write(')')
        monitor.write(' #E:' .. #id_events)
        monitor.write(' #A:' .. #id_alerts)
    end
end

runner:listen_for_event(nil, function(message)
    if message.type == PayloadType.EVENT then
        watch[message.host_id] = message
        if message.event.type ~= 'heartbeat' then
            if not events[message.host_id] then
                events[message.host_id] = {}
            end
            table.insert(events[message.host_id], message)
        end
        last_seen[message.host_id] = os.clock()
        update_term()
    else
        log:warning('Invalid message for event')
    end
end, true)

runner:listen_for_alert(nil, function(message)
    log:debug('alert')
    if message.type == PayloadType.ALERT then
        if not alerts[message.host_id] then
            alerts[message.host_id] = {}
        end
        table.insert(alerts[message.host_id], message)
        last_seen[message.host_id] = os.clock()
        update_term()
    else
        log:warning('Invalid message for alert')
    end
end, true)

runner:run()
