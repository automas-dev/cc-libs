local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('motion')

local ccl_location = require 'cc-libs.turtle.location'
local Action = ccl_location.Action
local Location = ccl_location.Location
local CompassName = ccl_location.CompassName
-- TODO is this needed for types?
local Compass = ccl_location.Compass

---@class Motion
---@field max_tries integer max attempts to move before failing
---@field can_dig boolean turtle can mine blocks in it's path
---@field location Location optional location tracking
local Motion = {}

-- TODO take map for updating
---Create a new motion controller
---@param location? Location location to be updated with motions
---@return Motion
function Motion:new(location)
    log:trace('New Motion instance')
    local o = {
        max_tries = 10,
        can_dig = false,
        location = location or Location:new(),
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---If a move fails, dig before the next attempt (default: false)
function Motion:enable_dig()
    self.can_dig = true
end

---Do not try to dig if a move fails
function Motion:disable_dig()
    self.can_dig = false
end

---Attempt an action up to self.max_tries times
---@private
---@param action function normally turtle.forward or .back or .up or .down
---@param fail_cb? function called if an attempt fails up to max attempts
---@return boolean was the move a success
function Motion:_attempt_move(action, fail_cb)
    local success = false
    local tries = 0
    for i = 1, self.max_tries do
        tries = i
        if action() then
            success = true
            break
        elseif turtle.getFuelLevel() == 0 then
            -- NOTE getFuelLevel can return "unlimited" if fuel consumption is disabled
            log:warning('Turtle is out of fuel')
            return false
        elseif fail_cb then
            fail_cb()
        end
    end
    log:trace('Attempt to move took', tries, 'tries and was', (success and 'success' or 'fail'))
    return success
end

---Move the turtle forward by n blocks
---@param n? integer number of blocks to move (default: 1)
---@return boolean
function Motion:forward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('move forward', n, 'blocks')
    for _ = 1, n do
        if not self:_attempt_move(turtle.forward, (self.can_dig and turtle.dig or nil)) then
            -- TODO is this warn in the right place?
            log:warning('Failed to move forward after ' .. self.max_tries .. 'attempts')
            return false
        end

        -- Update location after move
        self.location:update(Action.FORWARD)
    end
    return true
end

---Move the turtle backward by n blocks
---@param n? integer number of blocks to move (default: 1)
---@return boolean
function Motion:backward(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('move backward', n, 'blocks')
    for _ = 1, n do
        if not self:_attempt_move(turtle.back) then
            -- TODO is this warn in the right place?
            log:warning('Failed to move back after ' .. self.max_tries .. 'attempts')
            return false
        end

        -- Update location after move
        self.location:update(Action.BACKWARD)
    end
    return true
end

---Move the turtle up by n blocks
---@param n? integer number of blocks to move (default: 1)
---@return boolean
function Motion:up(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('move up', n, 'blocks')
    for _ = 1, n do
        if not self:_attempt_move(turtle.up, (self.can_dig and turtle.digUp or nil)) then
            -- TODO is this warn in the right place?
            log:warning('Failed to move up after ' .. self.max_tries .. 'attempts')
            return false
        end

        -- Update location after move
        self.location:update(Action.UP)
    end
    return true
end

---Move the turtle down by n blocks
---@param n? integer number of blocks to move (default: 1)
---@return boolean
function Motion:down(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('move down', n, 'blocks')
    for _ = 1, n do
        if not self:_attempt_move(turtle.down, (self.can_dig and turtle.digDown or nil)) then
            -- TODO is this warn in the right place?
            log:warning('Failed to move down after ' .. self.max_tries .. 'attempts')
            return false
        end

        -- Update location after move
        self.location:update(Action.DOWN)
    end
    return true
end

---Turn to the left n times
---@param n? integer number of turns to make
function Motion:left(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('turn left', n, 'times')

    if n == 0 then
        log:debug('n is 0, will do nothing')
        return
    end

    for i = 1, n do
        log:trace('Turn number', i)
        turtle.turnLeft()

        -- Update location after move
        self.location:update(Action.TURN_LEFT)
    end
end

---Turn to the right n times
---@param n? integer number of turns to make
function Motion:right(n)
    n = n or 1
    assert(n >= 0, 'n must be positive')
    log:debug('turn right', n, 'times')

    if n == 0 then
        log:debug('n is 0, will do nothing')
        return
    end

    for i = 1, n do
        log:trace('Turn number', i)
        turtle.turnRight()

        -- Update location after move
        self.location:update(Action.TURN_RIGHT)
    end
end

---Turn around by turning right twice
function Motion:around()
    self:right(2)
end

---Turn to face a direction based on heading from self.location
---@param compass Compass
function Motion:face(compass)
    assert(compass >= 1 and compass <= 4, 'Direction is an unknown value ' .. self.location.heading)
    log:trace('face', CompassName[compass])

    if not self.location.has_heading then
        log:warning('Location does not have a heading, this move is relative to the starting heading')
    end

    if compass == self.location.heading + 2 or compass == self.location.heading - 2 then
        self:around()
    elseif compass == self.location.heading + 1 or compass == self.location.heading - 3 then
        self:right()
    elseif compass == self.location.heading - 1 or compass == self.location.heading + 3 then
        self:left()
    end
end

local M = {
    Motion = Motion,
}

return M
