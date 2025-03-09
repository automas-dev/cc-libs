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

function test.find_torch()
    local mock = patch_local(actions, 'find_slot')
    mock.return_value = 2
    local slot = actions.find_torch()
    expect_eq(2, slot)
    expect_eq(1, mock.call_count)
    expect_eq('minecraft:torch', mock.args[1])
    expect_eq(1, mock.args[2])
end

function test.select_slot()
    local mock = patch_local(actions, 'find_slot')
    mock.return_value = 2
    local slot = actions.select_slot('name')
    expect_eq(2, slot)
    assert_eq(1, mock.call_count)
    expect_eq('name', mock.args[1])
    expect_eq(1, mock.args[2])
    assert_eq(1, turtle.select.call_count)
    expect_eq(2, turtle.select.args[1])
end

function test.select_slot_empty()
    local mock = patch_local(actions, 'find_slot')
    mock.return_value = nil
    local slot = actions.select_slot('name')
    expect_eq(nil, slot)
    assert_eq(1, mock.call_count)
    expect_eq('name', mock.args[1])
    expect_eq(1, mock.args[2])
    expect_eq(0, turtle.select.call_count)
end

function test.assert_fuel()
    turtle.getFuelLevel.return_value = 2
    local success, err = pcall(actions.assert_fuel, 2)
    expect_true(success, err)
end

function test.assert_fuel_fail()
    turtle.getFuelLevel.return_value = 1
    local success, _ = pcall(actions.assert_fuel, 2)
    expect_false(success)
end

function test.inventory_full_empty()
    turtle.getItemCount.return_value = 0
    expect_false(actions.inventory_full())
    expect_eq(1, turtle.getItemCount.call_count)
end

function test.inventory_full_single()
    turtle.getItemCount.return_sequence = { 1, 0 }
    expect_false(actions.inventory_full())
    expect_eq(2, turtle.getItemCount.call_count)
end

function test.inventory_full()
    turtle.getItemCount.return_value = 1
    expect_true(actions.inventory_full())
    expect_eq(16, turtle.getItemCount.call_count)
end

function test.dump_slot()
    -- Extra 2 for log call
    turtle.getItemCount.return_sequence = { 2, 2, 1, 0 }
    local count = actions.dump_slot(1)
    expect_eq(2, count)
    assert_eq(1, turtle.select.call_count)
    expect_eq(1, turtle.select.args[1])
    expect_eq(4, turtle.getItemCount.call_count)
    expect_eq(2, turtle.drop.call_count)
end

return test
