local all_mocks = {}

---Call reset on all Mock's that have been created
local function reset_mocks()
    for _, mock in ipairs(all_mocks) do
        mock.reset()
    end
end

---@class Mock
---@field call_count number how many times was this function called
---@field args any[] arguments of the last call
---@field calls any[][] arguments of each call
---@field return_value? any value to return when called
---@field return_unpack? any[] value to unpack and return when called
---@field return_sequence? any[] sequence of values to return on each call, last will be re-used
---@field return_sequence_unpack? any[][] sequence of values to unpack and return on each call, last will be re-used
---@field reset fun() reset mock
---@field reset_all fun() reset all mocks

---@param args? {return_value?: any, return_unpack?: any[], return_sequence?: any[], return_sequence_unpack?: any[][]}
---@return Mock
function MagicMock(args)
    args = args or {}
    local mock = {
        mt = {
            reserved = {
                'return_value',
                'return_unpack',
                'return_sequence',
                'return_sequence_unpack',
            },
        },
        call_count = 0,
        args = {},
        calls = {},
        reset_all = reset_mocks,
        return_value = args.return_value,
        return_unpack = args.return_unpack,
        return_sequence = args.return_sequence,
        return_sequence_unpack = args.return_sequence_unpack,
    }
    setmetatable(mock, mock.mt)
    table.insert(all_mocks, mock)

    mock.mt.__call = function(_, ...)
        mock.call_count = mock.call_count + 1
        mock.args = { ... }
        table.insert(mock.calls, mock.args)
        if mock.return_value ~= nil then
            return mock.return_value
        elseif mock.return_unpack ~= nil then
            return table.unpack(mock.return_unpack)
        elseif mock.return_sequence ~= nil then
            if #mock.return_sequence > 1 then
                return table.remove(mock.return_sequence, 1)
            end
            return mock.return_sequence[1]
        elseif mock.return_sequence_unpack ~= nil then
            if #mock.return_sequence_unpack > 1 then
                return table.unpack(table.remove(mock.return_sequence_unpack, 1))
            end
            return table.unpack(mock.return_sequence_unpack[1])
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
