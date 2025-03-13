term = {
    getCursorPos = function()
        return 0, 19
    end,
}
textutils = {
    pagedPrint = function(text, free_lines)
        print(text)
    end,
}

local argparse = require 'cc-libs.util.argparse'
local ArgParse = argparse.ArgParse

local ap = ArgParse:new('name', 'help message')
ap:add_arg('bob', 'is a builder', 'yes he can', false)
ap:add_option('o', 'out')
ap:add_option(nil, 'long', 'long option')
ap:add_option('s', 'short', 'short option')
ap:add_option('f', 'fmt', 'format', true)

ap:parse_args({ '-h' })
