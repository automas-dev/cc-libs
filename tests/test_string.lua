local str = require 'cc-libs.util.string'

local test = {}

function test.starts_with()
    expect_true(str.starts_with('abc', 'a'))
    expect_true(str.starts_with('abc', 'ab'))
    expect_true(str.starts_with('abc', 'abc'))

    expect_false(str.starts_with('', 'a'))
    expect_false(str.starts_with('a', 'ab'))
    expect_false(str.starts_with('ba', 'a'))
end

function test.ends_with()
    expect_true(str.ends_with('cba', 'a'))
    expect_true(str.ends_with('cba', 'ba'))
    expect_true(str.ends_with('cba', 'cba'))

    expect_false(str.ends_with('', 'a'))
    expect_false(str.ends_with('a', 'ba'))
    expect_false(str.ends_with('ab', 'a'))
end

function test.split()
    -- Normal cases
    expect_arr_eq({ 'a' }, str.split('a', ','))
    expect_arr_eq({ 'a', 'b' }, str.split('a,b', ','))
    expect_arr_eq({ 'a', 'bc', 'd' }, str.split('a,bc,d', ','))

    -- Start or end with empty
    expect_arr_eq({ '', 'a' }, str.split(',a', ','))
    expect_arr_eq({ 'a', '' }, str.split('a,', ','))

    -- Sequential empty
    expect_arr_eq({ 'a', '', '' }, str.split('a,,', ','))
    expect_arr_eq({ 'a', '', 'b' }, str.split('a,,b', ','))

    -- Empty start and end
    expect_arr_eq({ '', 'a', 'b', '' }, str.split(',a,b,', ','))

    -- Empty string
    expect_arr_eq({ '' }, str.split('', ','))

    -- Only sep
    expect_arr_eq({ '', '' }, str.split(',', ','))

    -- Only sep twice
    expect_arr_eq({ '', '', '' }, str.split(',,', ','))
end

function test.split_long_sep()
    -- Normal cases
    expect_arr_eq({ 'a' }, str.split('a', '..'))
    expect_arr_eq({ 'a', 'b' }, str.split('a..b', '..'))
    expect_arr_eq({ 'a', 'bc', 'd' }, str.split('a..bc..d', '..'))

    -- Start or end with empty
    expect_arr_eq({ '', 'a' }, str.split('..a', '..'))
    expect_arr_eq({ 'a', '' }, str.split('a..', '..'))

    -- Sequential empty
    expect_arr_eq({ 'a', '', '' }, str.split('a....', '..'))
    expect_arr_eq({ 'a', '', 'b' }, str.split('a....b', '..'))

    -- Empty start and end
    expect_arr_eq({ '', 'a', 'b', '' }, str.split('..a..b..', '..'))

    -- Empty string
    expect_arr_eq({ '' }, str.split('', '..'))

    -- Only sep
    expect_arr_eq({ '', '' }, str.split('..', '..'))

    -- Only sep twice
    expect_arr_eq({ '', '', '' }, str.split('....', '..'))
end

function test.split_max_count()
    expect_arr_eq({ 'a' }, str.split('a', ',', 1))
    expect_arr_eq({ 'a' }, str.split('a', ',', 2))
    expect_arr_eq({ 'a', '' }, str.split('a,', ',', 1))
    expect_arr_eq({ 'a', ',' }, str.split('a,,', ',', 1))

    expect_arr_eq({ 'a', 'b' }, str.split('a,b', ',', 1))

    expect_arr_eq({ 'a', ',b' }, str.split('a,,b', ',', 1))
    expect_arr_eq({ 'a', 'b,c' }, str.split('a,b,c', ',', 1))
    expect_arr_eq({ 'a', 'b', 'c' }, str.split('a,b,c', ',', 2))
    expect_arr_eq({ 'a', 'b', ',c' }, str.split('a,b,,c', ',', 2))
end

function test.rsplit()
    -- Normal cases
    expect_arr_eq({ 'a' }, str.rsplit('a', ','))
    expect_arr_eq({ 'a', 'b' }, str.rsplit('a,b', ','))
    expect_arr_eq({ 'a', 'bc', 'd' }, str.rsplit('a,bc,d', ','))

    -- Start or end with empty
    expect_arr_eq({ '', 'a' }, str.rsplit(',a', ','))
    expect_arr_eq({ 'a', '' }, str.rsplit('a,', ','))

    -- Sequential empty
    expect_arr_eq({ 'a', '', '' }, str.rsplit('a,,', ','))
    expect_arr_eq({ 'a', '', 'b' }, str.rsplit('a,,b', ','))

    -- Empty start and end
    expect_arr_eq({ '', 'a', 'b', '' }, str.rsplit(',a,b,', ','))

    -- Empty string
    expect_arr_eq({ '' }, str.rsplit('', ','))

    -- Only sep
    expect_arr_eq({ '', '' }, str.rsplit(',', ','))

    -- Only sep twice
    expect_arr_eq({ '', '', '' }, str.rsplit(',,', ','))
end

function test.rsplit_long_sep()
    -- Normal cases
    expect_arr_eq({ 'a' }, str.rsplit('a', '..'))
    expect_arr_eq({ 'a', 'b' }, str.rsplit('a..b', '..'))
    expect_arr_eq({ 'a', 'bc', 'd' }, str.rsplit('a..bc..d', '..'))

    -- Start or end with empty
    expect_arr_eq({ '', 'a' }, str.rsplit('..a', '..'))
    expect_arr_eq({ 'a', '' }, str.rsplit('a..', '..'))

    -- Sequential empty
    expect_arr_eq({ 'a', '', '' }, str.rsplit('a....', '..'))
    expect_arr_eq({ 'a', '', 'b' }, str.rsplit('a....b', '..'))

    -- Empty start and end
    expect_arr_eq({ '', 'a', 'b', '' }, str.rsplit('..a..b..', '..'))

    -- Empty string
    expect_arr_eq({ '' }, str.rsplit('', '..'))

    -- Only sep
    expect_arr_eq({ '', '' }, str.rsplit('..', '..'))

    -- Only sep twice
    expect_arr_eq({ '', '', '' }, str.rsplit('....', '..'))
end

function test.rsplit_max_count()
    expect_arr_eq({ 'a' }, str.rsplit('a', ',', 1))
    expect_arr_eq({ 'a' }, str.rsplit('a', ',', 2))
    expect_arr_eq({ 'a', '' }, str.rsplit('a,', ',', 1))
    expect_arr_eq({ 'a,', '' }, str.rsplit('a,,', ',', 1))

    expect_arr_eq({ 'a', 'b' }, str.rsplit('a,b', ',', 1))

    expect_arr_eq({ 'a,', 'b' }, str.rsplit('a,,b', ',', 1))
    expect_arr_eq({ 'a,b', 'c' }, str.rsplit('a,b,c', ',', 1))
    expect_arr_eq({ 'a', 'b', 'c' }, str.rsplit('a,b,c', ',', 2))
    expect_arr_eq({ 'a,b', '', 'c' }, str.rsplit('a,b,,c', ',', 2))
end

function test.gmatch()
    local pattern = '([^:]+)'
end

local l = '\\w+|"[\\w\\s]*"'

return test
