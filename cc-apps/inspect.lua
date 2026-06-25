-- Setup import paths
package.path = '../?.lua;../?/init.lua;' .. package.path

-- Import libraries
local json = require 'cc-libs.util.json'

local actions = require 'cc-libs.turtle.actions'

local exists, info = turtle.inspect()
if exists then
    print('Found block')
    local file = assert(io.open('inspect.json', 'w'))
    file:write(json.encode(info))
    file:close()
end

local inv = actions.examine_inventory('front')
if inv then
    print('Found inventory')
    local file = assert(io.open('inventory.json', 'w'))
    file:write(json.encode(inv))
    file:close()
end
