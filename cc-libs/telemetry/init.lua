local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('telemetry')

local json = require 'cc-libs.util.json'

local update_interval = 10 -- seconds

local M = {}

function M.send_telemetry()
    local fuel_level = turtle.getFuelLevel()
    local x, y, z = gps.locate()

    local status = {
        position = { x = x, y = y, z = z },
        fuel_level = fuel_level,

        -- luacheck: push ignore 143
        ---@diagnostic disable-next-line: undefined-field
        log_time = os.epoch('local') / 1000, -- luacheck: ignore
        ---@diagnostic disable-next-line: undefined-field
        host_id = os.getComputerID(),
        ---@diagnostic disable-next-line: undefined-field
        host_name = os.getComputerLabel() or '',
        --luacheck: pop
    }

    log:trace('Send telemetry')
    rednet.broadcast(json.encode(status), 'telemetry')
end

local function run_telemetry()
    peripheral.find('modem', rednet.open)

    while true do
        M.send_telemetry()
        sleep(update_interval)
    end
end

---@param new_interval_s number update interval in seconds
function M.set_update_interval(new_interval_s)
    update_interval = new_interval_s
end

function M.run_with_telemetry(fn, ...)
    local args = { ... }
    local function run_fn()
        return fn(table.unpack(args))
    end
    parallel.waitForAny(run_fn, run_telemetry)
end

return M
