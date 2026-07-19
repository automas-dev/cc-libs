local client = require 'cc-libs.kv.client'
local server = require 'cc-libs.kv.server'

return {
    KVClient = client.KVClient,
    KVServer = server.KVServer,
}
