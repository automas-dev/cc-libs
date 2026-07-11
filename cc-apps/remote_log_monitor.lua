-- Remember to update README.md with any changes here
package.path = '../?.lua;../?/init.lua;' .. package.path

local json = require 'cc-libs.util.json'
local logging = require 'cc-libs.util.logging'

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('remote_log_monitor', 'Read and echo remote logs')
parser:add_arg('level', { help = 'min log level to print' })
local args = parser:parse_args({ ... })

local level = logging.level_from_name(args.level)

peripheral.find('modem', rednet.open)

local fmt = logging.ShortFormatter:new()
local stream = logging.ConsoleStream:new()

while true do
    local id, message = rednet.receive('remote_log')
    local success, data = pcall(json.decode, message)
    if not success then
        print('Failed to decode message from ' .. id)
    elseif logging.level_from_name(data['level']) >= level then
        stream:send('[' .. data['host'] .. '] ' .. fmt:format_record(data), data)
    end
end
