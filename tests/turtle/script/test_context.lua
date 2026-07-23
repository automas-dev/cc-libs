local ccl_ts_context = require 'cc-libs.turtle.script.context'
local TSContext = ccl_ts_context.TSContext

local test = {}

function test.setup()
    patch('gps')
    -- Patched for logger
    patch('os.epoch').return_value = 0
    patch('os.getComputerID').return_value = 1
    patch('os.getComputerLabel').return_value = 'name'
end

---@return TSContext
local function make_ctx()
    local motion = Mock()
    local nav = Mock()
    local ctx = TSContext:new(motion, nav)
    return ctx
end

function test.new()
    local motion = Mock()
    local nav = Mock()
    local ctx = TSContext:new(motion, nav)
    expect_eq(motion, ctx.motion)
    expect_eq(nav, ctx.nav)
    expect_ne(nil, ctx.parser)
end

function test.register()
    local ctx = make_ctx()
    local function foo() end
    ctx:register('foo', false, foo)
    expect_eq(foo, ctx.native['foo'])
    expect_false(ctx.parser:does_token_take_arg('foo'))
end

function test.register_takes_arg()
    local ctx = make_ctx()
    local function foo() end
    ctx:register('foo', true, foo)
    expect_eq(foo, ctx.native['foo'])
    expect_true(ctx.parser:does_token_take_arg('foo'))
end

function test.simple_exec()
    local foo = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    assert_true(ctx:exec('foo'))
    assert_eq(1, foo.call_count)
    assert_eq(1, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
end

function test.simple_exec_count()
    local foo = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    assert_true(ctx:exec('foo 2'))
    assert_eq(1, foo.call_count)
    assert_eq(1, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(2, foo.args[2])
end

function test.simple_exec_with_arg()
    local foo = Mock()
    local ctx = make_ctx()
    ctx:register('foo', true, foo)
    assert_true(ctx:exec('foo bar'))
    assert_eq(1, foo.call_count)
    expect_eq(3, #foo.args)
    expect_eq(1, foo.args[2])
    expect_eq('bar', foo.args[3])
end

function test.simple_exec_with_arg_count()
    local foo = Mock()
    local ctx = make_ctx()
    ctx:register('foo', true, foo)
    assert_true(ctx:exec('foo bar 2'))
    assert_eq(1, foo.call_count)
    expect_eq(3, #foo.args)
    expect_eq(2, foo.args[2])
    expect_eq('bar', foo.args[3])
end

function test.loop_exec()
    local foo = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    assert_true(ctx:exec('[ foo ] 2'))
    assert_eq(2, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
end

function test.native_fails()
    local foo = Mock({ return_unpack = { false, 'error msg' } })
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    local success, err = ctx:exec('foo bar')
    assert_false(success)
    expect_eq('native function failed foo : error msg', err)
    assert_eq(1, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    expect_eq(0, bar.call_count)
end

function test.native_can_fail()
    local foo = Mock({ return_unpack = { false, 'error msg' } })
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    assert_true(ctx:exec('foo ?'))
    assert_eq(1, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    expect_eq(0, bar.call_count)
end

function test.native_repeat_until_fail()
    local foo = Mock({ return_sequence_unpack = {
        { true },
        { false, 'error msg' },
    } })
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    local success, err = ctx:exec('foo ! bar')
    assert_false(success)
    expect_eq('native function failed foo : error msg', err)
    assert_eq(2, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    expect_eq(0, bar.call_count)
end

function test.native_count_until_fail()
    local foo = Mock({
        return_sequence_unpack = {
            { true },
            { true },
            { false, 'error msg' },
        },
    })
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    assert_true(ctx:exec('foo #a bar'))
    assert_eq(3, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    assert_eq(1, bar.call_count)

    expect_eq(2, ctx.vars['a'])
end

function test.def_count_until_fail()
    local foo = Mock({
        return_sequence_unpack = {
            { true },
            { true },
            { false, 'error msg' },
        },
    })
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    assert_true(ctx:exec(':f foo ; f #a bar'))
    assert_eq(3, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    assert_eq(1, bar.call_count)

    expect_eq(2, ctx.vars['a'])
end

function test.native_count_from_var()
    local foo = Mock()
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    ctx.vars['a'] = 2
    assert_true(ctx:exec('foo $a bar'))
    assert_eq(1, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(2, foo.args[2])
    assert_eq(1, bar.call_count)

    expect_eq(2, ctx.vars['a'])
end

function test.def_count_from_var()
    local foo = Mock()
    local bar = Mock()
    local ctx = make_ctx()
    ctx:register('foo', false, foo)
    ctx:register('bar', false, bar)
    ctx.vars['a'] = 2
    assert_true(ctx:exec(':f foo; f $a bar'))
    assert_eq(2, foo.call_count)
    expect_eq(2, #foo.args)
    expect_eq(1, foo.args[2])
    assert_eq(1, bar.call_count)
end

function test.math_clear()
    local ctx = make_ctx()
    ctx:register_math()
    expect_eq(nil, ctx.vars['a'])
    assert_true(ctx:exec('clear a'))
    expect_eq(0, ctx.vars['a'])
end

function test.math_inc()
    local ctx = make_ctx()
    ctx:register_math()
    ctx.vars['a'] = 1
    assert_true(ctx:exec('inc a 2'))
    expect_eq(3, ctx.vars['a'])
    assert_true(ctx:exec('inc a'))
    expect_eq(4, ctx.vars['a'])
end

function test.math_dec()
    local ctx = make_ctx()
    ctx:register_math()
    ctx.vars['a'] = 2
    assert_true(ctx:exec('dec a 2'))
    expect_eq(0, ctx.vars['a'])
    assert_true(ctx:exec('dec a'))
    expect_eq(-1, ctx.vars['a'])
end

function test.math_with_var()
    local ctx = make_ctx()
    ctx:register_math()
    ctx.vars['a'] = 2
    ctx.vars['b'] = 1
    assert_true(ctx:exec('inc a $b'))
    expect_eq(3, ctx.vars['a'])
end

function test.math_lib()
    local res = nil
    local ctx = make_ctx()
    ctx:register_math()
    ctx:register('foo', true, function(_, _, arg)
        res = ctx.vars[arg]
        return true
    end)
    assert_true(ctx:exec('inc a 6 div a 3 inc a 9 div a 2 floor a foo a'))
    expect_eq(5, res)
end

return test
