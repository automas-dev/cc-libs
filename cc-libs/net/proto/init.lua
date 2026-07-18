local proto_model = require 'cc-libs.net.proto.model'
local proto_client = require 'cc-libs.net.proto.client'
local proto_server = require 'cc-libs.net.proto.server'

return {
    ProtocolClient = proto_client.ProtocolClient,
    ProtocolServer = proto_server.ProtocolServer,
    ResponseStatus = proto_model.ResponseStatus,
    Request = proto_model.Request,
    Response = proto_model.Response,
}
