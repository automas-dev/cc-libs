local all_mocks = {}

local function reset_mocks()
    for _, mock in ipairs(all_mocks) do
        mock.reset()
    end
end

---@return any
function MagicMock()
    local mock = {
        mt = {
            reserved = {
                'return_value',
                'return_sequence',
            },
        },
        call_count = 0,
        args = {},
        calls = {},
        reset_all = reset_mocks,
        return_value = nil,
        return_sequence = nil,
    }
    setmetatable(mock, mock.mt)
    table.insert(all_mocks, mock)

    mock.mt.__call = function(_, ...)
        mock.call_count = mock.call_count + 1
        mock.args = { ... }
        table.insert(mock.calls, mock.args)
        if mock.return_value then
            return mock.return_value
        elseif mock.return_sequence then
            if #mock.return_sequence > 1 then
                return table.remove(mock.return_sequence, 1)
            end
            return mock.return_sequence[1]
        else
            return nil
        end
    end

    mock.mt.__index = function(table, key)
        for _, opt in ipairs(mock.mt.reserved) do
            if opt == key then
                for k, v in pairs(mock) do
                    if k == key then
                        return v
                    end
                end
                return nil
            end
        end
        local new_mock = MagicMock()
        table[key] = new_mock
        return new_mock
    end

    mock.reset = function()
        mock.call_count = 0
        mock.args = {}
        mock.calls = {}
        mock.return_value = nil
        mock.return_sequence = nil
    end

    return mock
end
