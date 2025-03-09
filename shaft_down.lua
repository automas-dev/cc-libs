local logging = require 'cc-libs.util.logging'
logging.basic_config{
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'log/shaft_down.log'
}
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local args = { ... }
if #args < 1 then
    print('Usage: shaft_down <n> <block_walls>')
    print()
    print('Dig a shaft down and add walls if they are missing')
    print()
    print('Options:')
    print('    n: number of blocks to mine down')
    print('    block_walls: name of block to place as walls')
    return
end

local n = tonumber(args[1])
local block_wall = args[2]

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    log:fatal('Not enough fuel! Need', fuel_need)
end

local tmc = Motion:new()
tmc:enable_dig()

local function place()
    if not turtle.detect() then
        if actions.select_slot(block_wall) then
            turtle.place()
        else
            log:warning('Failed to find block', block_wall, 'for wall')
        end
    end
end

local function place_all_sides()
    for _ = 1, 4 do
        place()
        tmc:right()
    end
end

local total = 0
for _ = 1, n do
    if not tmc:down() then
        break
    end
    place_all_sides()
    total = total + 1
end

-- Return

log:info('Returning to station')

for _ = 1, total do
    tmc:up()
end

log:info('Done!')
