local logging = require 'cc-libs.util.logging'
logging.basic_config{
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'logs/tunnel2.log'
}
local log = logging.get_logger('main')

local actions = require 'cc-libs.turtle.actions'

local args = { ... }
if #args < 1 then
    print('Usage: tunnel2 <length> [return|false]')
    print()
    print('Options:')
    print('    length: length of the tunnel')
    print('    return: return to the start after finishing the tunnel')
    return
end

local length = tonumber(args[1])
local end_return = args[2] == 'true' or args[2] == 'yes'

log:info('Starting with parameters length=', length, 'return=', end_return)

turtle.up()

actions.dig_forward(length)

if end_return then
    turtle.left()
    turtle.left()
    actions.try_forward(length)
    turtle.left()
    turtle.left()
    turtle.down()
end
