package.path = '../?.lua;' .. package.path

local disable_color = os.getenv('DISABLE_COLOR_TEST')
local test_file_prefix = 'test_'
local test_function_prefix = 'test_'

require 'asserts'
require 'mock'

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

local function find_run_tests(test, test_module)
    print('Running tests from module ' .. test_module)
    local n_run = 0
    local n_pass = 0
    for name, fn in pairs(test) do
        if name ~= 'setup' and name ~= 'teardown' then
            local test_name = test_module .. '::' .. name
            if disable_color then
                print('[RUN    ] ' .. test_name)
            else
                print('\27[34m[RUN    ]\27[0m ' .. test_name)
            end
            if test.setup then
                test.setup()
            end
            local status, err = xpcall(fn, debug.traceback)
            if status then
                if disable_color then
                    print('[     OK] ' .. test_name)
                else
                    print('\27[32m[     OK]\27[0m ' .. test_name)
                end
                n_pass = n_pass + 1
            else
                if err.msg then
                    print(err.msg)
                else
                    print(err)
                end
                if disable_color then
                    print('[   FAIL] ' .. test_name)
                else
                    print('\27[31m[   FAIL]\27[0m ' .. test_name)
                end
            end
            if test.teardown then
                test.teardown()
            end
            n_run = n_run + 1
        end
    end
    print('Finished ' .. test_module .. ' ' .. n_pass .. '/' .. n_run .. ' passed')
    print()
    return n_run == n_pass
end

local n_test_run = 0
local n_test_pass = 0

for file in io.popen([[ls -ap | grep -v /]]):lines() do
    if file:find('^' .. test_file_prefix) and file:find('.lua$') then
        local module = file:sub(1, #file - 4)
        local old_g = save_g()
        local old_packages = save_packages()
        local success, test = xpcall(require, debug.traceback, module)
        if success then
            if find_run_tests(test, module) then
                n_test_pass = n_test_pass + 1
            end
            n_test_run = n_test_run + 1
        else
            print('failed to load test file', file)
        end
        reset_packages(old_packages)
        reset_g(old_g)
    end
end

if disable_color then
    print('Finished tests, ' .. n_test_pass .. ' passed of ' .. n_test_run)
elseif n_test_pass == n_test_run then
    print('\27[32mFinished tests, ' .. n_test_pass .. ' passed of ' .. n_test_run .. '\27[0m')
else
    print('\27[31mFinished tests, ' .. n_test_pass .. ' passed of ' .. n_test_run .. '\27[0m')
end


os.exit(n_test_pass == n_test_run)
