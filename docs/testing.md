# Unit test helpers

The `tests/` folder contains unit tests and the test harness including mocks, patches and expect / assert statements.
These helpers are intended for unit tests and are loaded by the test harness before each test file runs.

## Creating a test

Tests live in the `tests/` and its sub-directory and should be named with a `test_` prefix, such as `tests/test_example.lua`.
Each test should return a table containing one or more test functions and optional `setup()` and `teardown()` functions.
The harness will run each function as an individual test case and will call optional `setup()` and `teardown()` functions before and after each case.

### Example

```lua
local test = {}

function test.example()
    local result = 1 + 1
    expect_eq(2, result, 'addition should work')
end

return test
```

If a test needs temporary state, define `setup()` and `teardown()` in the same file to prepare and clean up shared resources.
Use `patch()` and `Mock` from the helpers in this document when a test needs to replace functions or objects.

### Example with setup, teardown, and patching:

```lua
local test = {}
local temp_file

function test.setup()
    -- create or prepare temporary test state here
    temp_file = '/tmp/test_data.txt'
    patch('print')
end

function test.teardown()
    -- clean up any resources created during the test
    os.remove(temp_file)
end

function test.example()
    print('this is patched')
    expect_true(temp_file ~= nil, 'setup should run before test cases')
    expect_eq(1, print.call_count, 'patched print should be tracked')
end

return test
```

As a best practice, use a local table named `test` to hold your test functions and define `setup()` and `teardown()` at the top of the file.
Because test cases are defined as `function test.something()`, a `test_` prefix is not needed for the case name (ie. don't use something like `function test.test_something()`).

## Expectation helpers

The `expect_*` helpers are non-throwing checks. They record a failure through the test harness but do not stop the test immediately.

They accept an optional message argument that is included in the failure report.

### All helpers

- `expect_eq(lhs, rhs, msg)`
- `expect_ne(lhs, rhs, msg)`
- `expect_gt(lhs, rhs, msg)`
- `expect_ge(lhs, rhs, msg)`
- `expect_lt(lhs, rhs, msg)`
- `expect_le(lhs, rhs, msg)`
- `expect_true(val, msg)`
- `expect_false(val, msg)`
- `expect_float_eq(lhs, rhs, msg)`
- `expect_float_ne(lhs, rhs, msg)`

### Example

```lua
expect_eq(10, result, 'unexpected result')
-- Because pcall returns a bool and message, it can be passed directly to expect_true
expect_true(pcall(something))
```

### Array helper

`expect_arr_eq(lhs, rhs, msg)` compares arrays by length and by index.
This is a shallow comparison and does not recursively check nested arrays.

```lua
expect_arr_eq({ 1, 2, 3 }, { 1, 2, 3 }, 'arrays should match')
```

## Assertion helpers

The `assert_*` helpers behave like the `expect_*` variants, except they raise a test assertion error after recording the failure.

This makes them useful when the current test should stop immediately after a failed condition.

### All helpers

- `assert_eq(lhs, rhs, msg)`
- `assert_ne(lhs, rhs, msg)`
- `assert_gt(lhs, rhs, msg)`
- `assert_ge(lhs, rhs, msg)`
- `assert_lt(lhs, rhs, msg)`
- `assert_le(lhs, rhs, msg)`
- `assert_true(val, msg)`
- `assert_false(val, msg)`
- `assert_float_eq(lhs, rhs, msg)`
- `assert_float_ne(lhs, rhs, msg)`

### Example

```lua
local mock = Mock()

assert_eq(0, mock.call_count, 'mock should not have been called yet')

mock('hello')
assert_eq(1, mock.call_count, 'mock should have been called once')
assert_eq(1, #mock.args, 'mock should have received exactly one argument')
expect_eq('hello', mock.args[1], 'mock should have received the expected argument')
```

### When to use which

- Use `expect_*` when you want to record a failure but keep going with the rest of the test.
- Use `assert_*` when a failed check means the test should abort immediately.

## Mock

`Mock` creates a callable mock object that can stand in for a function or method during tests.

A `Mock` will record:

- `call_count`: how many times the mock was called
- `args`: the arguments from the most recent call
- `calls`: a list of all calls made to the mock

It also supports specifying a return value or sequence:

- `return_value`: return the same value on every call
- `return_unpack`: unpack a list of values as the return values
- `return_sequence`: return values from a sequence, reusing the last value after the sequence is exhausted
- `return_sequence_unpack`: return a sequence of unpacked values, reusing the last tuple after the sequence is exhausted
- `custom_function`: run a custom function when the mock is called

All of the above fields are reserved in `Mock` objects along with `reset` and `reset_all`.
An error will be thrown if a value is assigned to any of these fields.

### Example

```lua
local mock = Mock()
mock.return_value = 42

local value = mock()
expect_eq(42, value)
expect_eq(1, mock.call_count)
expect_eq(0, #mock.args)
```

### Nested access

Accessing a missing field on a mock creates another mock automatically. This is useful when a test needs to mock a nested object or method chain.

```lua
local mock = Mock()
local child = mock.some.nested.method
child.return_value = 'ok'
```

### Resetting mocks

A mock can be reset with `mock.reset()`. This clears its all return values, recorded calls and counts.

`mock.reset_all()` resets all mocks globally.

## patch and patch_local

`patch` temporarily replaces a global variable with a `Mock` instance.

This is useful for stubbing globals such as `io.open` to inject or capture file contents,
or functions such as `os.getComputerID` that do not exist outside of the computercraft environment

### `patch(target)`

`patch` accepts a dotted string path and replaces the final field in that path with a mock. It returns the created `Mock` instance.

#### Examples

```lua
patch('print')
patch('io.open')
patch('os.getComputerID')
```

### `patch_local(obj, field)`

`patch_local` patches a specific field on a specific table and returns the created `Mock` instance.

#### Example

```lua
local foo = {}
function foo.bar()
    return 'foo'
end

local mock = patch_local(foo, 'bar')
mock.return_value = 'baz'
```

### Restoring patched values

Use `reset_patches()` to restore every previously patched value.

```lua
local old_print = print
local mock = patch('print')

print('hello')
expect_eq(1, mock.call_count)

reset_patches()
expect_eq(old_print, print)
```
