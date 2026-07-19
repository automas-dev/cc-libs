-- Setup import paths
package.path = '../../?.lua;../../?/init.lua;' .. package.path

-- Import and configure logging
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    level = logging.Level.DEBUG,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/kv_store.log',
}
local log = logging.get_logger('main')

local ccl_kv = require 'cc-libs.kv'
local KVServer = ccl_kv.KVServer

local function main()
    local server = KVServer('kv_store', 'kv_store')
    server:serve_forever()
end

log:catch_errors(main)
