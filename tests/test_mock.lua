local test = {}

function test.no_return()
    local mock = MagicMock()
    assert_eq(nil, mock())
end

function test.return_value()
    local mock = MagicMock()
    mock.return_value = 1
    assert_eq(1, mock())
    assert_eq(1, mock())
end

function test.return_sequence()
    local mock = MagicMock()
    mock.return_sequence = { 1, 2 }
    assert_eq(1, mock())
    assert_eq(2, mock())
    assert_eq(2, mock())
end

function test.return_value_priority()
    local mock = MagicMock()
    mock.return_value = 1
    mock.return_sequence = { 2, 3 }
    assert_eq(1, mock())
    assert_eq(1, mock())
end

function test.call_count()
    local mock = MagicMock()
    assert_eq(0, mock.call_count)
    mock()
    assert_eq(1, mock.call_count)
    mock()
    assert_eq(2, mock.call_count)
end

function test.args()
    local mock = MagicMock()
    assert_true(type(mock.args) == 'table')
    assert_eq(0, #mock.args)
    mock(1, '2')
    assert_eq(1, mock.args[1])
    assert_eq('2', mock.args[2])
    mock('3', 4)
    assert_eq('3', mock.args[1])
    assert_eq(4, mock.args[2])
    mock()
    assert_eq(0, #mock.args)
end

function test.calls()
    local mock = MagicMock()
    mock()
    mock(1)
    mock(2, 3)
    mock('4')
    mock()

    assert_eq(5, #mock.calls)

    assert_eq(0, #mock.calls[1])

    assert_eq(1, #mock.calls[2])
    assert_eq(1, mock.calls[2][1])

    assert_eq(2, #mock.calls[3])
    assert_eq(2, mock.calls[3][1])
    assert_eq(3, mock.calls[3][2])

    assert_eq(1, #mock.calls[4])
    assert_eq('4', mock.calls[4][1])

    assert_eq(0, #mock.calls[5])
end

function test.reset()
    local mock1 = MagicMock()
    local mock2 = MagicMock()
    mock1()
    mock2()
    mock1.reset()
    assert_eq(0, mock1.call_count)
    assert_eq(0, #mock1.args)
    assert_eq(0, #mock1.calls)

    assert_eq(1, mock2.call_count)
end

function test.reset_nested()
    local mock1 = MagicMock()
    mock1.mock2()
    mock1.reset()
    assert_eq(0, mock1.call_count)
    assert_eq(0, #mock1.args)
    assert_eq(0, #mock1.calls)

    assert_eq(1, mock1.mock2.call_count)
end

function test.reset_all()
    local mock1 = MagicMock()
    local mock2 = MagicMock()
    mock1()
    mock2()
    mock1.reset_all()
    assert_eq(0, mock1.call_count)
    assert_eq(0, #mock1.args)
    assert_eq(0, #mock1.calls)

    assert_eq(0, mock2.call_count)
    assert_eq(0, #mock2.args)
    assert_eq(0, #mock2.calls)
end

function test.reset_returns()
    local mock1 = MagicMock()
    local mock2 = MagicMock()
    mock1.return_value = 1
    mock2.return_sequence = { 2, 3 }
    mock1.reset_all()
    assert_eq(nil, mock1.return_value)
    assert_eq(nil, mock1.return_sequence)
    assert_eq(nil, mock2.return_value)
    assert_eq(nil, mock2.return_sequence)
end

return test
