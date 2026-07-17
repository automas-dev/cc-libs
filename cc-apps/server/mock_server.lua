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

local ccl_model = require 'cc-libs.net.proto.model_validate'
local FieldType = ccl_model.FieldType
local Schema = ccl_model.Schema

local server = ProtocolServer:new('mock', 'server')

server:route(
    '/guess',
    nil,
    ---@param request Request
    function(request)
        return request:ok_response({
            data = 'yes',
        })
    end
)

local req_model = Schema:new({
    name = { type = FieldType.STRING },
})

local resp_model = Schema:new({
    data = { type = FieldType.STRING },
})

server:route(
    '/guess/who',
    { request_model = req_model, response_model = resp_model },
    ---@param request Request
    function(request)
        return request:ok_response({
            data = 'yes',
        })
    end
)

-- Call serve_forever and log an error if raised
log:catch_errors(server.serve_forever, server)
