local argparse = require 'cc-libs.util.argparse'
local ArgParse = argparse.ArgParse

local test = {}

function test.setup()
    patch('term')['getCursorPos'].return_unpack = { 0, 19 }
    patch('textutils')
end

function test.new()
    local ap = ArgParse:new('name', 'help')
    expect_eq('name', ap.name)
    expect_eq('help', ap.help)
    expect_eq(0, #ap.args)
    expect_eq(0, #ap.options)
end

function test.new_no_help()
    local ap = ArgParse:new('name')
    expect_eq('name', ap.name)
    expect_eq(nil, ap.help)
    expect_eq(0, #ap.args)
    expect_eq(0, #ap.options)
end

function test.add_arg()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', 'help string', 'def', true)
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq('help string', ap.args[1].help)
    expect_eq('def', ap.args[1].default)
    expect_true(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_arg_after_multi()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', nil, nil, true)
    local success, err = pcall(ap.add_arg, ap, 'arg2')
    assert_false(success)
end

function test.add_arg_after_default()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', nil, 'default')
    assert_eq(1, #ap.args)
    expect_eq('default', ap.args[1].default)
    local success, err = pcall(ap.add_arg, ap, 'arg2')
    assert_false(success)
end

function test.add_arg_defaults()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq(nil, ap.args[1].help)
    expect_eq(nil, ap.args[1].default)
    expect_false(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_option()
    local ap = ArgParse:new('name')
    ap:add_option('o', 'out', 'output path', true)
    assert_eq(1, #ap.options)
    expect_eq('o', ap.options[1].short)
    expect_eq('out', ap.options[1].name)
    expect_eq('output path', ap.options[1].help)
    expect_true(ap.options[1].has_value)

    expect_eq(0, #ap.args)
end

function test.add_option_no_short()
    local ap = ArgParse:new('name')
    ap:add_option(nil, 'out', 'output path', true)
    assert_eq(1, #ap.options)
    expect_eq(nil, ap.options[1].short)
    expect_eq('out', ap.options[1].name)
    expect_eq('output path', ap.options[1].help)
    expect_true(ap.options[1].has_value)

    expect_eq(0, #ap.args)
end

function test.add_option_defaults()
    local ap = ArgParse:new('name')
    ap:add_option('o', 'out')
    assert_eq(1, #ap.options)
    expect_eq('o', ap.options[1].short)
    expect_eq('out', ap.options[1].name)
    expect_eq(nil, ap.options[1].help)
    expect_false(ap.options[1].has_value)

    expect_eq(0, #ap.args)
end

function test.parse_no_args()
    local ap = ArgParse:new('name')

    local args = ap:parse_args({})
    expect_eq(0, #args)
end

function test.parse_help_short()
    local ap = ArgParse:new('name')

    local mock_exit = patch('os.exit')
    local mock_print_help = patch_local(ap, 'print_help')

    ap:parse_args({ '-h' })
    expect_eq(1, mock_exit.call_count)
    assert_eq(1, #mock_exit.args)
    expect_eq(0, mock_exit.args[1])

    expect_eq(1, mock_print_help.call_count)
end

function test.parse_help_long()
    local ap = ArgParse:new('name')

    local mock_exit = patch('os.exit')
    local mock_print_help = patch_local(ap, 'print_help')

    ap:parse_args({ '--help' })
    expect_eq(1, mock_exit.call_count)
    assert_eq(1, #mock_exit.args)
    expect_eq(0, mock_exit.args[1])

    expect_eq(1, mock_print_help.call_count)
end

-- parse args

-- parse options

-- parse mix

-- parse errors (missing arg, invalid option, option with unexpected value)

return test
