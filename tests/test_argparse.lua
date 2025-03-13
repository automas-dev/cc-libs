local argparse = require 'cc-libs.util.argparse'
local ArgParse = argparse.ArgParse

local test = {}

function test.new()
    local ap = ArgParse:new('name', 'help')
    expect_eq('name', ap.name)
    expect_eq('help', ap.help)
    expect_eq(0, #ap.args)
    expect_eq(0, #ap.options)

    local args = ap:parse_args({})
    expect_eq(0, #args)
end

function test.new_no_help()
    local ap = ArgParse:new('name')
    expect_eq('name', ap.name)
    expect_eq(nil, ap.help)
    expect_eq(0, #ap.args)
    expect_eq(0, #ap.options)

    local args = ap:parse_args({})
    expect_eq(0, #args)
end

function test.help()
    local ap = ArgParse:new('name')
    expect_eq('name', ap.name)
    expect_eq(nil, ap.help)
    expect_eq(0, #ap.args)
    expect_eq(0, #ap.options)

    local mock = patch('os.exit')

    ap:parse_args({ '-h' })
    expect_eq(1, mock.call_count)
    assert_eq(1, #mock.args)
    expect_eq(0, mock.args[1])

    mock.reset()

    ap:parse_args({ '--help' })
    expect_eq(1, mock.call_count)
    assert_eq(1, #mock.args)
    expect_eq(0, mock.args[1])
end

function test.add_arg()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', 'help string', 'def', true)
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq('help string', ap.args[1].help)
    expect_eq('def', ap.args[1].default)
    expect_false(ap.args[1].is_multi)

    expect_eq(0, #ap.options)
end

function test.add_arg_after_multi()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1', nil, nil, true)
    pcall(ap.add_arg, ap, 'arg2')
end

-- multi arg error

function test.add_arg_defaults()
    local ap = ArgParse:new('name')
    ap:add_arg('arg1')
    assert_eq(1, #ap.args)
    expect_eq('arg1', ap.args[1].name)
    expect_eq('', ap.args[1].help)
    expect_eq(nil, ap.args[1].default)
    expect_false(ap.args[1].is_multi)

    expect_eq(0, #ap.options)

    local args = ap:parse_args({})
    expect_eq(0, #args)
end

-- default arg error

-- add option with short

-- add option no short

-- add option defaults

-- parse no args

-- parse help

-- parse args

-- parse options

-- parse mix

-- parse errors (missing arg, invalid option, option with unexpected value)

return test
