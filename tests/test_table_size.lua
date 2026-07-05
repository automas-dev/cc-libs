local table_size = require 'cc-libs.util.table_size'

local test = {}

function test.table_size()
    local table = {}
    expect_eq(0, table_size(table))

    table = { a = 1 }
    expect_eq(1, table_size(table))

    table = { a = 1, b = 3 }
    expect_eq(2, table_size(table))
end

return test
