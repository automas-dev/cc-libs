package.path = '../?.lua;../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.FATAL,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/startup.log',
    remote_enabled = true,
}

local ccl_telemetry = require 'cc-libs.net.telemetry'
local get_telemetry = ccl_telemetry.get_telemetry

local json = require 'cc-libs.util.json'

local TELEMETRY_SLEEP_S = 10
local REMOTE_CONTROL_PROTOCOL = 'remote_control'
local REMOTE_CONTROL_RESPONSE_PROTOCOL = 'remote_control'

local function telemetry()
    local log = logging.get_logger('telemetry')

    local telem = get_telemetry()

    local function main()
        while true do
            log:info('Send telemetry')
            telem:update_state()
            log:debug('Finished sending telemetry')

            os.sleep(TELEMETRY_SLEEP_S)
        end
    end

    log:catch_errors(main)
end

local function remote_control()
    local log = logging.get_logger('remote_control')

    while true do
        local id, message = rednet.receive(REMOTE_CONTROL_PROTOCOL)
        if id == nil then
            log:warning('Got message from nil id')
        else
            local success, data = pcall(json.decode, message)
            if not success then
                log:error('Failed to decode message from', id)
            else
                if data.id ~= os.getComputerID() then
                    log:debug('Message not for me, got id', data.id)
                elseif not data.command or #data.command == 0 then
                    log:warning('Got empty command')
                else
                    -- TODO can output be captured and returned to caller?
                    local command_success = shell.execute(table.unpack(data.command))
                    rednet.send(id, json.encode({ success = command_success }), REMOTE_CONTROL_RESPONSE_PROTOCOL)
                end
            end
        end
    end
end

local function local_shell()
    -- Clear os name and version from root shell
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)

    shell.run('shell')
end

local function wait_for_q()
    local telem = get_telemetry()
    while true do
        local key
        repeat
            local _
            _, key = os.pullEvent('key')
        until key == keys.q
        -- print('Q was pressed!')
        telem:send_event('key_press', '', { key = key })
    end
end

parallel.waitForAny(telemetry, local_shell, wait_for_q, remote_control)
shell.exit()
