package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    -- Ideally there should be no console logs enabled
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/kv_client.log',
    remote_enabled = true,
}
local log = logging.get_logger('main')

-- Argument parsing
local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('kv_client', 'Get or set a value from the kv server')
parser:add_arg('op', { help = 'get, set or history' })
parser:add_arg('key', { help = 'key of entry' })
parser:add_arg('value', { help = 'value if operations is set', required = false })
parser:add_option('v', 'verbose', 'Output more information')
local args = parser:parse_args({ ... })

local op = args.op
assert(op == 'get' or op == 'set' or op == 'history', 'op must be get, set or history')
local key = args.key
local value = args.value
local verbose = args.verbose or false

if op == 'set' then
    assert(value ~= nil, 'value must be given for set')
end

local pretty = require 'cc-libs.util.pretty'

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolClient = ccl_proto.ProtocolClient

local function main()
    local client = ProtocolClient:new('kv_store', 'server', 5)
    if op == 'get' then
        local success, status, resp = client:request('get', { key = key })
        ---@cast resp table
        if success then
            if not resp.found then
                log:info('Key', key, 'is not set')
            else
                local entry = resp.entry
                if verbose then
                    pretty.pprint('Got value', entry.value)
                    pretty.pprint('Set by', entry.set_by_id, entry.set_by_host)
                    pretty.pprint('Last updated', entry.last_update)
                else
                    pretty.pprint(entry.value)
                end
            end
        else
            log:error('Failed to get key', key, status, resp)
        end
    elseif op == 'history' then
        local success, status, resp = client:request('get_history', { key = key })
        ---@cast resp table
        if success then
            if not resp.found then
                log:info('Key', key, 'is not set')
            else
                local entry = resp.entry
                local history = resp.history
                for _, v in ipairs(history) do
                    pretty.pprint(v.last_update, v.value)
                end
                pretty.pprint(entry.last_update, entry.value)
            end
        else
            log:error('Failed to get key', key, status, resp)
        end
    elseif op == 'set' then
        local success, status, resp = client:request('set', {
            entry = {
                key = key,
                value = value,
                set_by_host = os.getComputerLabel(),
                set_by_id = os.getComputerID(),
            },
        })
        if success then
            if verbose then
                pretty.pprint('Set value of', key, 'to', value)
            end
        else
            log:error('Failed to assign key', key, status, resp)
        end
    else
        error('Unknown op ' .. tostring(op))
    end
end

log:catch_errors(main)
