-- Setup import paths
package.path = '../../?.lua;../../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.DEBUG,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/mock_server.log',
}
local log = logging.get_logger('main')

local ccl_proto = require 'cc-libs.net.proto'
local ProtocolServer = ccl_proto.ProtocolServer

local server = ProtocolServer:new('mock', 'server')

---@param request Request
server:route('/guess', function(request)
    return request:ok_response({
        data = 'yes',
    })
end)

-- Call serve_forever and log an error if raised
log:catch_errors(server.serve_forever, server)
