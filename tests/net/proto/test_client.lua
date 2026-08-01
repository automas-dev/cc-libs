local test = {}

local ccl_kv = require 'cc-libs.kv'

local function create_client_mock()
    -- Patched for logger
    patch('os.epoch')
    patch('os.getComputerID')
    patch('os.getComputerLabel')

    local ccl_proto = require 'cc-libs.net.proto'

    -- Patch ProtoClient:new to return mock
    local mock_new = patch_local(ccl_proto.ProtocolClient, 'new')

    -- Store mocked routes
    local mc = {
        paths = {},
        client = Mock(),
    }

    ---Register new route
    ---@param path string
    ---@param status? ResponseStatus
    ---@param message? string|table
    function mc.mock_route(path, status, message)
        mc.paths[path] = {
            status = status,
            message = message,
        }
    end
    mock_new.return_value = mc.client

    -- Handle request by calling function or returning registered response
    function mock_request_handler(_, path, body, timeout)
        local res = mc.paths[path]
        if type(res) == 'function' then
            return res(path, body, timeout)
        elseif res then
            return res.status == 'ok', res.status, res.message
        else
            return false, 'not_found'
        end
    end
    mc.client.request.custom_function = mock_request_handler

    return mc
end

function test.one()
    local mock = create_client_mock()
    mock.mock_route('get', 'ok', { found = true, entry = { value = 'foo' } })
    local client = ccl_kv.KVClient:new('host')
    local success, value = client:get('key')
    expect_true(success)
    expect_eq('foo', value)
end

return test
