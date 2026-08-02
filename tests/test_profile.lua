local ccl_profile = require 'cc-libs.profile'
local Profiler = ccl_profile.Profiler

local test = {}

function test.setup()
    local i = 0
    patch('os.clock').custom_function = function()
        i = i + 1
        return i
    end
    -- Patched for logger
    patch('os.epoch').return_value = 0
    patch('os.getComputerID').return_value = 1
    patch('os.getComputerLabel').return_value = 'name'
end

function test.new()
    local p = Profiler:new()
    assert_ne(nil, p.results)
    expect_eq(0, #p.results)
end

function test.wrap_call()
    local p = Profiler:new()
    assert_ne(nil, p.results)
    expect_eq(0, #p.results)

    local name = 'foo'
    local function fn()
        return 'bar'
    end

    local res = p:wrap_call(name, fn)
    expect_eq('bar', res)
    assert_ne(nil, p.results[name])
    expect_arr_eq({ 1 }, p.results[name])

    res = p:wrap_call(name, fn)
    expect_eq('bar', res)
    expect_arr_eq({ 1, 1 }, p.results[name])
end

function test.wrap_fn()
    local p = Profiler:new()
    assert_ne(nil, p.results)
    expect_eq(0, #p.results)

    local name = 'foo'
    local fn = p:wrap_fn(name, function()
        return 'bar'
    end)

    local res = fn()
    expect_eq('bar', res)
    assert_ne(nil, p.results[name])
    expect_arr_eq({ 1 }, p.results[name])

    res = fn()
    expect_eq('bar', res)
    expect_arr_eq({ 1, 1 }, p.results[name])
end

function test.wrap_nested()
    local p = Profiler:new()
    assert_ne(nil, p.results)
    expect_eq(0, #p.results)

    local foo = p:wrap_fn('foo', function()
        expect_eq(2, Profiler.active)
    end)

    local bar = p:wrap_fn('bar', function()
        expect_eq(1, Profiler.active)
        foo()
        expect_eq(1, Profiler.active)
    end)

    bar()
    assert_ne(nil, p.results['foo'])
    expect_arr_eq({ 1 }, p.results['foo'])
    assert_ne(nil, p.results['bar'])
    expect_arr_eq({ 3 }, p.results['bar'])
end

return test
