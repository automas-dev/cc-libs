local test = {}

function test.normalize_coverage_path()
    local runtests = require 'runtests'
    expect_eq('cc-libs/util/json.lua', runtests.normalize_coverage_path('../cc-libs/util/json.lua'))
    expect_eq('cc-libs/util/json.lua', runtests.normalize_coverage_path('./cc-libs/util/json.lua'))
    expect_eq('cc-apps/main.lua', runtests.normalize_coverage_path('./cc-apps/main.lua'))
end

function test.is_coverage_target()
    local runtests = require 'runtests'
    expect_true(runtests.is_coverage_target('cc-libs/util/json.lua'))
    expect_true(runtests.is_coverage_target('cc-apps/benchmark.lua'))
    expect_false(runtests.is_coverage_target('tests/test_runtests.lua'))
    expect_false(runtests.is_coverage_target('stub/cc-tweaked-documentation/lua.lua'))
end

function test.resolve_coverage_path()
    local runtests = require 'runtests'
    expect_eq('../cc-libs/util/json.lua', runtests.resolve_coverage_path('cc-libs/util/json.lua'))
    expect_eq('../cc-apps/benchmark.lua', runtests.resolve_coverage_path('cc-apps/benchmark.lua'))
end

function test.should_count_coverage_line()
    local runtests = require 'runtests'
    expect_true(runtests.should_count_coverage_line('local value = 1'))
    expect_true(runtests.should_count_coverage_line('  return value'))
    expect_true(runtests.should_count_coverage_line('local value = 1 -- inline comment'))
    expect_false(runtests.should_count_coverage_line(''))
    expect_false(runtests.should_count_coverage_line('   '))
    expect_false(runtests.should_count_coverage_line('-- comment'))
    expect_false(runtests.should_count_coverage_line('   -- comment'))
end

return test
