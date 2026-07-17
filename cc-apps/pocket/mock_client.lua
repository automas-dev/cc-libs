package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.DEBUG,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/mock_client.log',
}
local log = logging.get_logger('main')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolClient = ccl_proto.ProtocolClient

local function main()
    log:info('Opening client')
    local client = ProtocolClient:new('mock', 'server')
    log:info('Opened client')
    local success, status, resp = client:request('/guess', nil, 5)
    if success then
        log:info('Got success response from server', status, resp)
    else
        log:warning('Got unsuccessful response from server', status, resp)
    end

    success, status, resp = client:request('/guess/who', { name = 'bob' }, 5)
    if success then
        log:info('Got success response from server', status, resp)
    else
        log:warning('Got unsuccessful response from server', status, resp)
    end
end

-- Call main and log an error if raised
-- log:catch_errors(main)
main()
