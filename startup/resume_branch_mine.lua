package.path = '../?.lua;../?/init.lua;' .. package.path
local json = require 'cc-libs.util.json'

if fs.exists('.active') then
    print('Found .active, resuming branch mine')

    -- Give GPS nodes time to start
    sleep(1)

    local file = assert(io.open('.active', 'r'))
    local params = json.decode(file:read('a'))
    shell.run('cc/branch_mine.lua', params.shafts, params.length, params.torch, params.skip)
end
