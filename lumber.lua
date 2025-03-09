local logging = require 'cc-libs.util.logging'
logging.basic_config{
    level = logging.Level.INFO,
    file_level = logging.Level.DEBUG,
    filepath = 'log/lumber.log'
}
logging.file_level = logging.Level.DEBUG
local log = logging.get_logger('main')

---@module 'ccl_motion'
local ccl_motion = require 'cc-libs.turtle.motion'

local log_types = {
    ['minecraft:oak_log'] = true,
    ['minecraft:spruce_log'] = true,
    ['minecraft:birch_log'] = true,
    ['minecraft:jungle_log'] = true,
    ['minecraft:acacia_log'] = true,
    ['minecraft:dark_oak_log'] = true,
    ['minecraft:mangrove_log'] = true,
    ['minecraft:cherry_log'] = true,
    ['minecraft:crimson_stem'] = true,
    ['minecraft:warped_stem'] = true,
    ['minecraft:stripped_oak_log'] = true,
    ['minecraft:stripped_spruce_log'] = true,
    ['minecraft:stripped_birch_log'] = true,
    ['minecraft:stripped_jungle_log'] = true,
    ['minecraft:stripped_acacia_log'] = true,
    ['minecraft:stripped_dark_oak_log'] = true,
    ['minecraft:stripped_mangrove_log'] = true,
    ['minecraft:stripped_cherry_log'] = true,
    ['minecraft:stripped_crimson_stem'] = true,
    ['minecraft:stripped_warped_stem'] = true,
}

local tmc = ccl_motion.Motion:new()
tmc:enable_dig()

local height = 0

while true do
    local exists, info = turtle.inspect()
    if not exists or not log_types[info.name] then
        break
    end
    turtle.dig()
    tmc:up()
    height = height + 1
end

-- Return

log:info('Returning to station')
tmc:down(height)

log:info('Done!')
