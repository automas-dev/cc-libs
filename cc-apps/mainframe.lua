package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/mainframe.log',
}
local log = logging.get_logger('main')

local json = require 'cc-libs.util.json'

local turtle_states = {}

local function proto_telemetry(id, message)
    log:info('proto telemetry')
    local success, data = pcall(json.decode, message)
    log:debug('Finish decode')
    if not success then
        log:error('Failed to decode message from', id)
        return
    end
    if not turtle_states[id] then
        log:debug('Found turtle for id', id)
        turtle_states[id] = {
            id = id,
        }
    end
    log:debug('Updating state')
    for k, v in pairs(data) do
        turtle_states[id][k] = v
    end
end

local function proto_report(id, message)
    log:info('proto report')
    local success, data = pcall(json.decode, message)
    local response = nil
    if not success then
        log:error('Failed to decode message from', id)
        response = {
            ok = false,
            err = 'Bad message',
        }
    elseif not data.id then
        log:debug('Missing id', data)
        response = {
            ok = false,
            err = 'Missing id',
        }
    elseif not turtle_states[data.id] then
        log:debug('Unknown id', data.id)
        response = {
            ok = false,
            err = 'Unknown id',
        }
    else
        response = {
            ok = true,
            id = data.id,
            status = turtle_states[data.id],
        }
    end
    log:info('Respond to', id)
    rednet.send(id, json.encode(response), 'mainframe_response')
end

local protocols = {
    telemetry = proto_telemetry,
    report = proto_report,
}

local function run_telemetry()
    log:info('Starting telemetry thread')

    peripheral.find('modem', rednet.open)
    log:debug('Rednet open')

    while true do
        local id, message, protocol = rednet.receive()
        log:info('Got message', message, 'from id', id, 'with protocol', protocol)
        local proto = protocols[protocol]
        if proto then
            log:debug('Found handler for protocol', protocol)
            log:catch_errors(proto, id, message)
        end
    end
end

local function run_remote_log()
    log:info('Starting remote log thread')

    local log_files = {}

    local fmt = logging.ShortFormatter:new()
    local stream = logging.ConsoleStream:new()

    while true do
        local id, message = rednet.receive('remote_log')
        local success, data = pcall(json.decode, message)
        if not success then
            log:error('Failed to decode message from', id)
        else
            if logging.level_from_name(data['level']) >= logging.Level.WARNING then
                stream:send('[' .. data['host'] .. '] ' .. fmt:format_record(data))
            end
            local file_handle = log_files[data.host]
            if not file_handle then
                file_handle = logging.FileStream:new('logs/remote/' .. data['host'] .. '.json')
                log_files[data.host] = file_handle
            end
            file_handle:send(message)
        end
    end
end

log:catch_errors(parallel.waitForAny, run_remote_log, run_telemetry)
