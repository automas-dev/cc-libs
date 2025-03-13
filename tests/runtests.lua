package.path = '../?.lua;../?/init.lua;' .. package.path

local disable_color = os.getenv('DISABLE_COLOR_TEST')
local verbose = os.getenv('VERBOSE')
local test_file_prefix = 'test_'

require 'asserts'
require 'asserts_extra'
require 'mock'
require 'patch'

local json = require 'cc-libs.util.json'

---Save the state of globals _G with a shallow copy
---@return table old_g shallow copy of G
local function save_g()
    local copy = {}
    for key, value in pairs(_G) do
        copy[key] = value
    end
    return copy
end

---Restore the state of globals _G from with the snapshot created by save_g.
---This only removes or adds keys that are not present in the shallow copy. Any
---changed -bellow an existing key will not be reverted.
---@param old_g table snapshot of _G
local function reset_g(old_g)
    for key, _ in pairs(_G) do
        if not old_g[key] then
            _G[key] = nil
        end
    end
end

---Save the state of loaded packages with a shallow copy
---@return table old_packages shallow copy of packages.loaded
local function save_packages()
    local copy = {}
    for key, value in pairs(package.loaded) do
        copy[key] = value
    end
    return copy
end

---Restore the state of packages with the snapshot created by save_packages.
---This will only remove packages that were loaded since the call to
---save_packages
---@param old_packages table shallow copy of packages.loaded
local function reset_packages(old_packages)
    for key, _ in pairs(package.loaded) do
        if not old_packages[key] then
            package.loaded[key] = nil
        end
    end
end

---@class CheckFail
---@field msg string any message about the failure
---@field file string file calling the check
---@field line number line of call to the check
---@field test string test module / file name
---@field case string test case / function name
---@field check string check name
---@field data table extra data about the check

---Run single test case from a test module / file
---@param fn fun()
---@param case_name string test case / function name
---@param test_name string test module / file name
---@return boolean status did the case pass
---@return CheckFail[] failed_checks array of all checks that failed in the case
local function run_test_case(fn, case_name, test_name)
    ---@type CheckFail[]
    local failed_checks = {}

    ---Global function to capture checks that failed
    ---@param data table data about the check failure
    function store_check_fail(data)
        local check_name = debug.getinfo(2, 'n').name
        local info = debug.getinfo(3, 'Sl')

        -- Keep message separate from any other data
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

    -- Call / run the case function
    local status, err = xpcall(fn, debug.traceback)

    -- Store check fail for an error if there was one
    if not status then
        -- Only capture errors that were not form an assert_*
        if type(err) == 'string' then
            store_check_fail({
                msg = err,
                type = 'system error',
            })
        end
    end

    return #failed_checks == 0, failed_checks
end

---@class TestCase
---@field name string test case / function name
---@field status 'pass'|'fail' pass if all cases passed
---@field failed_checks CheckFail[] list array of all checks that failed in the case

---Run all test cases in a module
---@param test any
---@param test_name string test module / file name
---@return boolean status did all the cases pass
---@return TestCase[] cases data about each test case that ran
local function run_test_module(test, test_name)
    print('Running tests from module ' .. test_name)
    local n_pass = 0
    local cases = {}

    local test_names = {}
    for name, _ in pairs(test) do
        table.insert(test_names, name)
    end

    table.sort(test_names)

    for _, fn_name in ipairs(test_names) do
        local fn = test[fn_name]
        -- Do not run setup or teardown as test cases
        if fn_name ~= 'setup' and fn_name ~= 'teardown' then
            -- Call setup if it exists
            if test.setup then
                test.setup()
            end

            -- Run the test case and capture failed checks
            local status, failed_checks = run_test_case(fn, fn_name, test_name)
            if status then
                n_pass = n_pass + 1
            end

            -- Call teardown if it exists
            if test.teardown then
                test.teardown()
            end

            -- Reset any patches applied during setup or case
            reset_patches()

            -- Store any failed checks
            table.insert(cases, {
                name = fn_name,
                status = status and 'pass' or 'fail',
                failed_checks = not status and failed_checks or nil,
            })
        end
    end

    return #cases == n_pass, cases
end

---Print the test results and details of each test case including failed checks
---@param test_name string test module / file name
---@param cases TestCase[] array of all test cases in the module
local function print_test_trace(test_name, cases)
    local n_run = 0
    local n_pass = 0

    for _, case in ipairs(cases) do
        local case_name = test_name .. '::' .. case.name

        -- Print header line of case
        if disable_color then
            print('[RUN    ] ' .. case_name)
        else
            -- Blue
            print('\27[34m[RUN    ]\27[0m ' .. case_name)
        end

        -- Print the status footer
        if case.status == 'pass' then
            if disable_color then
                print('[     OK] ' .. case_name)
            else
                -- Green
                print('\27[32m[     OK]\27[0m ' .. case_name)
            end
        else
            -- Print each check if any failed
            for _, check in ipairs(case.failed_checks) do
                if check.data.type ~= 'system error' then
                    print(check.file .. ':' .. check.line)
                end
                print(check.msg)
            end

            if disable_color then
                print('[   FAIL] ' .. case_name)
            else
                -- Red
                print('\27[31m[   FAIL]\27[0m ' .. case_name)
            end
        end

        if case.status == 'pass' then
            n_pass = n_pass + 1
        end
        n_run = n_run + 1
    end

    print('Finished ' .. test_name .. ' ' .. n_pass .. '/' .. n_run .. ' passed')
    print()
end

local n_test_run = 0
local n_test_pass = 0
local all_test_results = {}

for file in io.popen([[ls -ap | grep -v /]]):lines() do
    -- Is this a lua test file
    if file:find('^' .. test_file_prefix) and file:find('.lua$') then
        local module = file:sub(1, #file - 4)
        local cases = {}

        -- Store state of globals and packages before loading test file
        local old_g = save_g()
        local old_packages = save_packages()

        local success, test = xpcall(require, debug.traceback, module)
        if success then
            success, cases = run_test_module(test, module)
            if success then
                n_test_pass = n_test_pass + 1
            end

            -- Only print case details if there was a fail or verbose is enabled
            if not success or verbose then
                print_test_trace(module, cases)
            end
        else
            if disable_color then
                print('Failed to load test file ' .. file)
            else
                -- Yellow
                print('\27[33mFailed to load test file ' .. file .. '\27[0m')
            end
            print(test)
        end

        n_test_run = n_test_run + 1
        table.insert(all_test_results, {
            name = module,
            cases = cases,
            status = success and 'pass' or 'fail',
        })

        -- Restore state of globals and packages after running all cases to
        -- prevent side effects.
        reset_packages(old_packages)
        reset_g(old_g)
    end
end

-- Dump test results to a report json file
local test_file = io.open('test_report.json', 'w')
if test_file then
    test_file:write(json.encode(all_test_results))
    test_file:close()
end

if disable_color then
    print('Finished tests, ' .. n_test_pass .. ' passed of ' .. n_test_run)
elseif n_test_pass == n_test_run then
    -- Green
    print('\27[32mFinished tests ' .. n_test_pass .. '/' .. n_test_run .. ' passed\27[0m')
else
    -- Red
    print('\27[31mFinished tests ' .. n_test_pass .. '/' .. n_test_run .. ' passed\27[0m')
end

os.exit(n_test_pass == n_test_run)
