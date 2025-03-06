package.path = '../?.lua;../?/init.lua;' .. package.path

local disable_color = os.getenv('DISABLE_COLOR_TEST')
local test_file_prefix = 'test_'

require 'asserts'
require 'mock'

local json = require 'cc-libs.util.json'

local function save_g()
    local copy = {}
    for key, value in pairs(_G) do
        copy[key] = value
    end
    return copy
end

local function save_packages()
    local copy = {}
    for key, value in pairs(package.loaded) do
        copy[key] = value
    end
    return copy
end

local function reset_g(old_g)
    for key, _ in pairs(_G) do
        if not old_g[key] then
            _G[key] = nil
        end
    end
end

local function reset_packages(old_packages)
    for key, _ in pairs(package.loaded) do
        if not old_packages[key] then
            package.loaded[key] = nil
        end
    end
end

local function run_test_case(fn, case_name, test_name)
    local failed_checks = {}

    function store_check_fail(data)
        local check_name = debug.getinfo(2, 'n').name
        local info = debug.getinfo(3, 'Sl')
        local msg = data.msg
        data.msg = nil
        table.insert(failed_checks, {
            file = data.file or info.source,
            line = data.line or info.currentline,
            test = test_name,
            case = case_name,
            check = check_name,
            msg = msg,
            data = data,
        })
    end

    local status, err = xpcall(fn, debug.traceback)
    if not status then
        if type(err) == 'string' then
            store_check_fail({
                msg = err,
                type = 'system error',
            })
        end
    end

    return #failed_checks == 0, failed_checks
end

local function find_run_tests(test, test_module)
    print('Running tests from module ' .. test_module)
    local n_pass = 0
    local cases = {}

    for fn_name, fn in pairs(test) do
        if fn_name ~= 'setup' and fn_name ~= 'teardown' then
            if test.setup then
                test.setup()
            end
            local status, failed_checks = run_test_case(fn, fn_name, test_module)
            if status then
                n_pass = n_pass + 1
            end
            if test.teardown then
                test.teardown()
            end
            table.insert(cases, {
                name = fn_name,
                status = status and 'pass' or 'fail',
                failed_checks = not status and failed_checks or nil
            })
        end
    end
    return #cases == n_pass, cases
end

local function print_test_trace(test_module, cases)
    local n_run = 0
    local n_pass = 0

    for _, case in pairs(cases) do
        if case.status == 'pass' then
            n_pass = n_pass + 1
        end
        local test_name = test_module .. '::' .. case.name
        if disable_color then
            print('[RUN    ] ' .. test_name)
        else
            print('\27[34m[RUN    ]\27[0m ' .. test_name)
        end
        if case.status == 'pass' then
            if disable_color then
                print('[     OK] ' .. test_name)
            else
                print('\27[32m[     OK]\27[0m ' .. test_name)
            end
        else
            for _, check in ipairs(case.failed_checks) do
                if check.data.type ~= 'system error' then
                    print(check.file .. ':' .. check.line)
                end
                print(check.msg)
            end
            if disable_color then
                print('[   FAIL] ' .. test_name)
            else
                print('\27[31m[   FAIL]\27[0m ' .. test_name)
            end
        end
        n_run = n_run + 1
    end
    print('Finished ' .. test_module .. ' ' .. n_pass .. '/' .. n_run .. ' passed')
    print()
end

local n_test_run = 0
local n_test_pass = 0
local all_test_results = {}

for file in io.popen([[ls -ap | grep -v /]]):lines() do
    if file:find('^' .. test_file_prefix) and file:find('.lua$') then
        local module = file:sub(1, #file - 4)
        local old_g = save_g()
        local old_packages = save_packages()
        local success, test = xpcall(require, debug.traceback, module)
        local cases = {}
        if success then
            success, cases = find_run_tests(test, module)
            if success then
                n_test_pass = n_test_pass + 1
            else
                print_test_trace(module, cases)
            end
        else
            if disable_color then
                print('Failed to load test file ' .. file)
            else
                print('\27[33mFailed to load test file ' .. file .. '\27[0m')
            end
            print(test)
        end
        n_test_run = n_test_run + 1
        table.insert(all_test_results, {
            name = module,
            cases = cases,
            status = success and 'pass' or 'fail'
        })
        reset_packages(old_packages)
        reset_g(old_g)
    end
end

local test_file = io.open('test_report.json', 'w')
if test_file then
    test_file:write(json.encode(all_test_results))
    test_file:close()
end

if disable_color then
    print('Finished tests, ' .. n_test_pass .. ' passed of ' .. n_test_run)
elseif n_test_pass == n_test_run then
    print('\27[32mFinished tests ' .. n_test_pass .. '/' .. n_test_run .. ' passed\27[0m')
else
    print('\27[31mFinished tests ' .. n_test_pass .. '/' .. n_test_run .. ' passed\27[0m')
end


os.exit(n_test_pass == n_test_run)
