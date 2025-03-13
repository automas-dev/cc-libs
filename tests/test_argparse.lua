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
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Argument arg2 cannot be evaluated after is_multi arg arg1$'))
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
    mock_exit.custom_function = error
    local mock_print_help = patch_local(ap, 'print_help')

    local success, err = pcall(ap.parse_args, ap, { '-h' })
    assert_false(success)
    expect_eq(1, mock_exit.call_count)
    assert_eq(1, #mock_exit.args)
    expect_eq(0, mock_exit.args[1])

    expect_eq(1, mock_print_help.call_count)
end

function test.parse_help_long()
    local ap = ArgParse:new('name')

    local mock_exit = patch('os.exit')
    mock_exit.custom_function = error
    local mock_print_help = patch_local(ap, 'print_help')

    local success, err = pcall(ap.parse_args, ap, { '--help' })
    assert_false(success)
    expect_eq(1, mock_exit.call_count)
    assert_eq(1, #mock_exit.args)
    expect_eq(0, mock_exit.args[1])

    expect_eq(1, mock_print_help.call_count)
end

function test.parse_args()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    ap:add_arg('arg2')

    local args = ap:parse_args({ 'a', 'b' })
    expect_eq('a', args.arg1)
    expect_eq('b', args.arg2)
end

function test.parse_args_default()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', nil, 'def1')
    ap:add_arg('arg2', nil, 'def2')

    local args = ap:parse_args({ 'a' })
    expect_eq('a', args.arg1)
    expect_eq('def2', args.arg2)
end

function test.parse_args_missing()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')

    local success, err = pcall(ap.parse_args, ap, {})
    expect_false(success)
end

function test.parse_options()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')
    ap:add_option(nil, 'opt2')
    ap:add_option(nil, 'opt3')

    local args = ap:parse_args({ '-a', '--opt2' })
    expect_true(args.opt1)
    expect_true(args.opt2)
    expect_false(args.opt3)
end

function test.parse_options_out_of_order()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')
    ap:add_option(nil, 'opt2')

    local args = ap:parse_args({ '--opt2', '-a' })
    expect_true(args.opt1)
    expect_true(args.opt2)
end

function test.parse_options_value()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1', nil, true)

    local args = ap:parse_args({ '-a', 'val' })
    expect_eq('val', args.opt1)
end

function test.parse_options_invalid_short()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local success, err = pcall(ap.parse_args, ap, { '-a', '-i' })
    expect_false(success)
end

function test.parse_options_invalid_long()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local success, err = pcall(ap.parse_args, ap, { '-a', '--invalid' })
    expect_false(success)
end

function test.parse_options_unexpected_value()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local success, err = pcall(ap.parse_args, ap, { '-a', 'val' })
    expect_false(success)
end

function test.parse_options_missing_value()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1', nil, true)

    local success, err = pcall(ap.parse_args, ap, { '-a' })
    expect_false(success)
end

function test.parse_mix()
    local ap = ArgParse:new('name')
    ap:add_arg('first')
    ap:add_arg('second')
    ap:add_arg('third')
    ap:add_option('a', 'opt1', nil, true)
    ap:add_option('b', 'opt2')
    ap:add_option(nil, 'opt3')

    local args = ap:parse_args({ '-a', 'val', '1', '2', '--opt2', '3' })
    expect_eq('1', args.first)
    expect_eq('2', args.second)
    expect_eq('3', args.third)
    expect_eq('val', args.opt1)
    expect_true(args.opt2)
    expect_false(args.opt3)
end

-- help message

-- logging

return test
