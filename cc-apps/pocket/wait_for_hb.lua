package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/wait_for_hb.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry
local PayloadType = ccl_telemetry.PayloadType

local telem = get_telemetry()
local runner = telem:make_runner()

-- Remember, time runs faster in game
local GAME_TIME_FACTOR = 72
local HB_TIMEOUT_s = 10 * GAME_TIME_FACTOR

local function clear_term()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
end

---@type { [integer] : EventTelemetryPayload }
local watch = {}

local function update_term()
    clear_term()
    local keys = {}
    for i in pairs(watch) do
        table.insert(keys, i)
    end
    table.sort(keys)
    local now = os.epoch('ingame') / 1000
    for _, i in ipairs(keys) do
        local msg = watch[i]
        if msg.time_ingame + HB_TIMEOUT_s < now then
            term.setTextColor(colors.red)
        else
            term.setTextColor(colors.green)
        end
        write(i)
        term.setTextColor(colors.white)
        -- write(':' .. msg.host_name .. ' ' .. math.floor(msg.time_ingame) .. ' (')
        write(':' .. msg.host_name .. ' (')
        if msg.pos then
            write(math.floor(msg.pos.x) .. ',' .. math.floor(msg.pos.y) .. ',' .. math.floor(msg.pos.z) .. ',')
        end
        if msg.has_fix then
            write('f,')
        end
        if msg.has_fix then
            write('h')
        end
        print(')')
    end
end

runner:listen_for_event('heartbeat', function(message)
    assert(message.type == PayloadType.EVENT)
    watch[message.host_id] = message
    update_term()
end, true)

runner:run()
