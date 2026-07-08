---@diagnostic disable: undefined-field
-- luacheck: ignore 143 142

local ccl_vec = require 'cc-libs.util.vec'
local Vec3 = ccl_vec.Vec3

local record = require 'cc-libs.util.logging.record'
local Record = record.Record

local test = {}

function test.setup()
    patch('os.getComputerID').return_value = 7
    patch('os.getComputerLabel').return_value = 'name'
    patch('_G.gps').locate.return_unpack = { 1, 2, 3 }
end

function test.record()
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('ss', r.subsystem)
    expect_eq(1, r.level)
    expect_eq('lc', r.location)
    expect_eq('msg', r.message)
    expect_eq(1234, r.time)
    expect_eq(7, r.host_id)
    expect_eq('name', r.host_name)
    expect_eq(Vec3:new(1, 2, 3), r.gps)
end

function test.record_no_label()
    ---@diagnostic disable-next-line: inject-field
    os.getComputerLabel.return_value = nil
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('ss', r.subsystem)
    expect_eq(1, r.level)
    expect_eq('lc', r.location)
    expect_eq('msg', r.message)
    expect_eq(1234, r.time)
    expect_eq(7, r.host_id)
    expect_eq('', r.host_name)
    expect_eq(Vec3:new(1, 2, 3), r.gps)
end

function test.record_no_gps()
    ---@diagnostic disable-next-line: inject-field
    os.getComputerLabel.return_value = nil
    ---@diagnostic disable-next-line: inject-field
    _G.gps.locate.return_unpack = { nil, nil, nil }
    local r = Record:new('ss', 1, 'lc', 'msg', 1234)
    expect_eq('ss', r.subsystem)
    expect_eq(1, r.level)
    expect_eq('lc', r.location)
    expect_eq('msg', r.message)
    expect_eq(1234, r.time)
    expect_eq(7, r.host_id)
    expect_eq('', r.host_name)
    expect_eq(nil, r.gps)
end

return test
