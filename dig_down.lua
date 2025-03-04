local logging = require 'cc-libs.util.logging'
logging.file = 'logs/dig_down.log'
logging.level = logging.Level.INFO
logging.file_level = logging.Level.DEBUG
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'

local args = { ... }
if #args < 1 then
    print('Usage: dig_down <n>')
    print()
    print('Options:')
    print('    n: number of blocks to mine down')
    return
end

local n = tonumber(args[1])

log:info('Starting with parameters n=', n)

log:info('Starting fuel level', turtle.getFuelLevel())
local fuel_need = n * 2
log:debug('Fuel needed is', fuel_need)
if turtle.getFuelLevel() < fuel_need then
    log:fatal('Not enough fuel! Need', fuel_need)
end

local tmc = ccl_motion.Motion:new()
tmc:enable_dig()

local total = 0
for _ = 1, n do
    if not tmc:down() then
        break
    end
    total = total + 1
end

-- Return

log:info('Returning to station')

for _ = 1, total do
    tmc:up()
end

log:info('Done!')
