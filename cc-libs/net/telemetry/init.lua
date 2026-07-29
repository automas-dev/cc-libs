local telem_runner = require 'cc-libs.net.telemetry.runner'
local telem = require 'cc-libs.net.telemetry.telemetry'

return {
    TelemetryRunner = telem_runner.TelemetryRunner,
    Telemetry = telem.Telemetry,
    TELEMETRY_PROTOCOL = telem.TELEMETRY_PROTOCOL,
    PayloadType = telem.PayloadType,
    get_telemetry = telem.get_telemetry,
}
