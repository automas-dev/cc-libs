package.path = '../../?.lua;../../?/init.lua;' .. package.path
local logging = require 'cc-libs.util.logging'
logging.basic_config {
    filepath = 'logs/structure.log',
}
local log = logging.get_logger('main')

local argparse = require 'cc-libs.util.argparse'
local parser = argparse.ArgParse:new('structure', 'Build basic structures')
parser:add_arg('name', { help = 'structure name' })
local args = parser:parse_args({ ... })

local ccl_motion = require 'cc-libs.turtle.motion'
local Motion = ccl_motion.Motion

local actions = require 'cc-libs.turtle.actions'

local json = require 'cc-libs.util.json'

local structure_path = 'structures/' .. args.name .. '.json'

if not fs.exists(structure_path) then
    log:fatal('Could not find a structure at', structure_path)
end

log:info('Loading structure from', structure_path)

local file = assert(io.open(structure_path, 'r'))
local structure = json.decode(file:read('a'))
file:close()

local tmc = Motion:new()

local aliases = structure.aliases
local layers = structure.layers
local structure_size = structure.size

-- TODO get list of blocks needed

log:info('Begin construction')

for layer_no, layer in ipairs(layers) do
    local pattern = layer.pattern

    log:debug('Begin layer', layer_no)

    tmc:up()
    tmc:right()

    for r, row in ipairs(pattern) do
        for c, col in ipairs(row) do
            if aliases[col] ~= nil then
                col = aliases[col]
            end
            if col then
                if actions.select_slot(col) then
                    log:trace('Place block', col)
                    turtle.placeDown()
                else
                    log:warning('Failed to find block', col)
                end
            else
                log:trace('Skipping block')
            end
            if c < #row then
                tmc:forward()
            end
        end

        if r == #pattern then
            break
        end

        log:trace('Turning around')

        if r % 2 == 0 then
            tmc:right()
            tmc:forward()
            tmc:right()
        else
            tmc:left()
            tmc:forward()
            tmc:left()
        end
    end

    log:debug('Returning to start for next layer')

    if structure_size.z % 2 == 1 then
        tmc:around()
        tmc:forward(structure_size.x - 1)
    end

    tmc:left()
    tmc:forward(structure_size.z - 1)
    tmc:around()
end

tmc:backward()
tmc:around()
tmc:down(structure_size.y)

log:info('Done!')
