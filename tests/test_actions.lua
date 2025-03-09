local actions = require 'cc-libs.turtle.actions'

local test = {}

function test.setup()
    patch('turtle')
end

function test.find_slot()
    turtle.getItemDetail.return_sequence = {
        { name = 'fake' },
        nil,
        { name = 'name' },
    }
    turtle.getItemCount.return_value = 1
    local slot = actions.find_slot('name', 1)
    expect_eq(3, slot)
    expect_eq(3, turtle.getItemDetail.call_count)
end

function test.find_slot_empty()
    turtle.getItemDetail.return_sequence = nil
    turtle.getItemCount.return_value = 1
    local slot = actions.find_slot('name', 1)
    expect_eq(nil, slot)
    expect_eq(16, turtle.getItemDetail.call_count)
end

function test.find_slot_not_enough()
    turtle.getItemDetail.return_value = { name = 'name' }
    turtle.getItemCount.return_value = 1
    local slot = actions.find_slot('name', 2)
    expect_eq(nil, slot)
    expect_eq(16, turtle.getItemDetail.call_count)
end

function test.find_slot_second()
    turtle.getItemDetail.return_value = { name = 'name' }
    turtle.getItemCount.return_sequence = { 1, 2 }
    local slot = actions.find_slot('name', 2)
    expect_eq(2, slot)
    expect_eq(2, turtle.getItemDetail.call_count)
end

return test
