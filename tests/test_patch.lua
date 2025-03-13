local test = {}

local foo = {}

function foo.bar()
    return 'foo'
end

function test.patch_local()
    expect_eq('foo', foo.bar())
    local mock = patch_local(foo, 'bar')
    mock.return_value = 'baz'
    expect_eq('baz', foo.bar())
    reset_patches()
    expect_eq('foo', foo.bar())
end

function test.patch_local_repeat()
    local mock1 = patch_local(foo, 'bar')
    local mock2 = patch_local(foo, 'bar')
    expect_eq(mock1, mock2)
end

function test.patch()
    local old_print = print
    local mock = patch('print')
    print('test')
    expect_eq(1, mock.call_count)
    expect_eq('test', mock.args[1])
    reset_patches()
    expect_eq(old_print, print)
end

function test.patch_path()
    local old_open = io.open
    local mock = patch('io.open')
    mock.return_value = 'hi'
    local f = io.open('test', 'a')
    expect_eq('hi', f)
    expect_eq(1, mock.call_count)
    expect_eq('test', mock.args[1])
    expect_eq('a', mock.args[2])
    reset_patches()
    expect_eq(old_open, io.open)
end

return test
