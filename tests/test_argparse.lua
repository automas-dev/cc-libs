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
    ap:add_arg('arg1', {
        help = 'help string',
        default = 'def',
        is_multi = true,
    })
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq('help string', ap.args[1].help)
    expect_eq('def', ap.args[1].default)
    expect_false(ap.args[1].required)
    expect_true(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_arg_optional()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', {
        help = 'help string',
        required = false,
        is_multi = true,
    })
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq('help string', ap.args[1].help)
    expect_eq(nil, ap.args[1].default)
    expect_false(ap.args[1].required)
    expect_true(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_arg_defaults()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq(nil, ap.args[1].help)
    expect_eq(nil, ap.args[1].default)
    expect_true(ap.args[1].required)
    expect_false(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_arg_duplicate()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    local success, err = pcall(ap.add_arg, ap, 'arg1')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Argument arg1 already exists'), 'Unexpected error message ' .. tostring(err))
end

function test.add_arg_option_duplicate()
    local ap = ArgParse:new('name')
    ap:add_option(nil, 'arg1')
    local success, err = pcall(ap.add_arg, ap, 'arg1')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg1 has the same name as option arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_after_optional()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { required = false })
    local success, err = pcall(ap.add_arg, ap, 'arg2')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after optional arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_after_default()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { default = 'def' })
    local success, err = pcall(ap.add_arg, ap, 'arg2')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after default arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_after_multi()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { is_multi = true })
    local success, err = pcall(ap.add_arg, ap, 'arg2')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after is_multi arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_optional_after_default()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { default = 'def' })
    local success, err = pcall(ap.add_arg, ap, 'arg2', { required = false })
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after default arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_optional_after_multi()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { is_multi = true })
    local success, err = pcall(ap.add_arg, ap, 'arg2', { required = false })
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after is_multi arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
end

function test.add_arg_default_after_multi()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { is_multi = true })
    local success, err = pcall(ap.add_arg, ap, 'arg2', { default = 'def' })
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(
        err:find('Argument arg2 cannot be evaluated after is_multi arg arg1'),
        'Unexpected error message ' .. tostring(err)
    )
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

function test.add_option_duplicate()
    local ap = ArgParse:new('name')
    ap:add_option(nil, 'out')
    local success, err = pcall(ap.add_option, ap, nil, 'out')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Option out already exists'), 'Unexpected error message ' .. tostring(err))
end

function test.add_option_arg_duplicate()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    local success, err = pcall(ap.add_option, ap, nil, 'arg1')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Option arg1 has the same name as arg arg1'), 'Unexpected error message ' .. tostring(err))
end

function test.add_option_short_with_minus()
    local ap = ArgParse:new('name')
    local success, err = pcall(ap.add_option, ap, '-o', 'out')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Short cannot include -'), 'Unexpected error message ' .. tostring(err))
end

function test.add_option_long_with_minus()
    local ap = ArgParse:new('name')
    local success, err = pcall(ap.add_option, ap, 'o', '-out')
    assert_false(success)
    assert(err ~= nil, 'err is nil')
    expect_true(err:find('Name cannot include -'), 'Unexpected error message ' .. tostring(err))
end

function test.parse_no_args()
    local ap = ArgParse:new('name')

    local args = ap:parse_args({})
    expect_eq(0, #args)
end

function test.parse_help_short()
    local ap = ArgParse:new('name')

    local mock_print_help = patch_local(ap, 'print_help')

    local args = ap:parse_args({ '-h' })
    expect_eq(nil, args)

    expect_eq(1, mock_print_help.call_count)
end

function test.parse_help_long()
    local ap = ArgParse:new('name')

    local mock_print_help = patch_local(ap, 'print_help')

    local args = ap:parse_args({ '--help' })
    expect_eq(nil, args)

    expect_eq(1, mock_print_help.call_count)
end

function test.parse_args()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    ap:add_arg('arg2')

    local args = ap:parse_args({ 'a', 'b' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_eq('a', args.arg1)
    expect_eq('b', args.arg2)
end

function test.parse_args_default()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', { default = 'def1' })
    ap:add_arg('arg2', { default = 'def2' })

    local args = ap:parse_args({ 'a' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_eq('a', args.arg1)
    expect_eq('def2', args.arg2)
end

function test.parse_args_missing()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')

    local mock_print = patch('print')

    local args = ap:parse_args({})
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Missing required positional arguments arg1', mock_print.args[1])
end

function test.parse_options()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')
    ap:add_option(nil, 'opt2')
    ap:add_option(nil, 'opt3')

    local args = ap:parse_args({ '-a', '--opt2' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_true(args.opt1)
    expect_true(args.opt2)
    expect_false(args.opt3)
end

function test.parse_options_out_of_order()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')
    ap:add_option(nil, 'opt2')

    local args = ap:parse_args({ '--opt2', '-a' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_true(args.opt1)
    expect_true(args.opt2)
end

function test.parse_options_value()
    local ap = ArgParse:new('name')
    ap:add_option('z', 'opt1', nil, true)

    local args = ap:parse_args({ '-z', 'val' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_eq('val', args.opt1)
end

function test.parse_options_bad_short()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local mock_print = patch('print')

    local args = ap:parse_args({ '--a' })
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Unexpected option --a', mock_print.args[1])
end

function test.parse_options_invalid_short()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local mock_print = patch('print')

    local args = ap:parse_args({ '-a', '-i' })
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Unexpected option -i', mock_print.args[1])
end

function test.parse_options_invalid_long()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local mock_print = patch('print')

    local args = ap:parse_args({ '-a', '--invalid' })
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Unexpected option --invalid', mock_print.args[1])
end

function test.parse_options_unexpected_value()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1')

    local mock_print = patch('print')

    local args = ap:parse_args({ '-a', 'val' })
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Unexpected value val', mock_print.args[1])
end

function test.parse_options_missing_value()
    local ap = ArgParse:new('name')
    ap:add_option('a', 'opt1', nil, true)

    local mock_print = patch('print')

    local args = ap:parse_args({ '-a' })
    expect_eq(nil, args)
    assert_eq(1, mock_print.call_count)
    expect_eq('Missing value for option -a', mock_print.args[1])
end

function test.parse_mix()
    local ap = ArgParse:new('name')
    ap:add_arg('first')
    ap:add_arg('second')
    ap:add_arg('third', { is_multi = true })
    ap:add_option('a', 'opt1', nil, true)
    ap:add_option('b', 'opt2')
    ap:add_option(nil, 'opt3')

    local args = ap:parse_args({ '-a', 'val', '1', '2', '--opt2', '3', '4' })
    assert_ne(nil, args)
    assert(args ~= nil, 'args was nil') -- to make linter happy
    expect_eq('1', args.first)
    expect_eq('2', args.second)
    expect_eq('3', args.third[1])
    expect_eq('4', args.third[2])
    expect_eq('val', args.opt1)
    expect_true(args.opt2)
    expect_false(args.opt3)
end

function test.help_message_basic()
    local ap = ArgParse:new('name')

    local mock_textutils = patch('textutils')

    ap:print_help()

    assert_eq(1, mock_textutils.pagedPrint.call_count)
    assert_eq('Usage: name\n\n', mock_textutils.pagedPrint.args[1])
end

function test.help_message_description()
    local ap = ArgParse:new('name', 'description')

    local mock_textutils = patch('textutils')

    ap:print_help()

    assert_eq(1, mock_textutils.pagedPrint.call_count)
    assert_eq('Usage: name\n\ndescription\n', mock_textutils.pagedPrint.args[1])
end

function test.help_message_args()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    ap:add_arg('arg2', { help = 'arg help', required = false })
    ap:add_arg('arg3', { help = 'more arg help', default = 'def' })

    local mock_textutils = patch('textutils')

    ap:print_help()

    assert_eq(1, mock_textutils.pagedPrint.call_count)
    assert_eq(
        [[Usage: name <arg1> [arg2] [arg3|def]

Args:
    arg1:
    arg2: arg help
    arg3: more arg help
]],
        mock_textutils.pagedPrint.args[1]
    )
end

function test.help_message_options()
    local ap = ArgParse:new('name')
    ap:add_option('o', 'output')
    ap:add_option(nil, 'input', 'option help')
    ap:add_option(nil, 'format', 'more help', true)

    local mock_textutils = patch('textutils')

    ap:print_help()

    assert_eq(1, mock_textutils.pagedPrint.call_count)
    assert_eq(
        [[Usage: name [options]

Options:
    -o/--output:
    --input: option help
    --format format: more help
]],
        mock_textutils.pagedPrint.args[1]
    )
end

function test.help_message_mixed()
    local ap = ArgParse:new('name', 'description')
    ap:add_arg('first', { help = 'help string' })
    ap:add_arg('second', { required = false })
    ap:add_arg('third', { help = 'third arg', default = 'abcd' })
    ap:add_option('a', 'opt1', nil, true)
    ap:add_option('b', 'opt2', 'help here')
    ap:add_option(nil, 'opt3')

    local mock_textutils = patch('textutils')

    ap:print_help()

    assert_eq(1, mock_textutils.pagedPrint.call_count)
    assert_eq(
        [[Usage: name [options] <first> [second] [third|abcd]

description
Args:
    first: help string
    second:
    third: third arg
Options:
    -a/--opt1 opt1:
    -b/--opt2: help here
    --opt3:
]],
        mock_textutils.pagedPrint.args[1]
    )
end

-- logging

return test
