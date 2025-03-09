local test = {}

function test.remove_value()
    local t = { 1, 2, 3 }
    table.remove(t)
    expect_arr_eq(t, { 1, 2 })
    table.remove(t)
    expect_arr_eq(t, { 1 })
    table.remove(t)
    expect_arr_eq(t, {})
end

function test.remove_index()
    local t = { 1, 2, 3 }
    table.remove(t, 1)
    expect_arr_eq(t, { 2, 3 })
    table.remove(t, 1)
    expect_arr_eq(t, { 3 })
    table.remove(t, 1)
    expect_arr_eq(t, {})
end

function test.remove_nil_after()
    local t = { 1, 2, nil }
    table.remove(t, 1)
    expect_arr_eq(t, { 2, nil })
    table.remove(t, 1)
    expect_arr_eq(t, { nil })
    table.remove(t, 1)
    expect_arr_eq(t, {})
end

function test.remove_nil_before()
    local t = { nil, 2, 3 }
    table.remove(t, 1)
    expect_arr_eq(t, { 2, 3 })
    table.remove(t, 1)
    expect_arr_eq(t, { 3 })
    table.remove(t, 1)
    expect_arr_eq(t, {})
end

--- In lua 5.2 this will pass, array ends at first nil
--- In lua 5.4+ this will pass
function test.remove_nil_center()
    local t = { 1, nil, 3 }
    expect_arr_eq({ 1, nil, 3 }, t)
    table.remove(t, 1)
    expect_arr_eq(t, { nil })
    table.remove(t, 1)
    expect_arr_eq(t, {})
    table.remove(t, 1)
    expect_arr_eq(t, {})
end

return test
