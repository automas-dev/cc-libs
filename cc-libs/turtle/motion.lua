local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('motion')

local json = require 'cc-libs.util.json'

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
---@field telemetry? Telemetry used to send alerts if an action fails
---@field motion_fail_cb? function called if an action fails
---@field log_fails boolean create a warning log message if an action fails
local Motion = {}

-- TODO take map for updating
---Create a new motion controller
---@param location? Location location to be updated with motions
---@param motion_fail_cb? function called if an action fails
---@return Motion
function Motion:new(location, motion_fail_cb)
    log:trace('New Motion instance')
    local o = {
        max_tries = 10,
        can_dig = false,
        location = location or Location:new(),
        telemetry = nil,
        motion_fail_cb = motion_fail_cb,
        log_fails = true,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Attach telemetry to broadcast alerts for failed actions
---@param telemetry Telemetry
function Motion:attach_telemetry(telemetry)
    -- TODO add more telemetry events from Motion
    self.telemetry = telemetry
end

---If a move fails, dig before the next attempt (default: false)
function Motion:enable_dig()
    self.can_dig = true
end

---Do not try to dig if a move fails
function Motion:disable_dig()
    self.can_dig = false
end

---Broadcast an alert using telemetry for a failed action
---@private
---@param action string human readable name for action
---@param attempts number how many retries occurred before failing
function Motion:_telem_alert_fail(action, attempts)
    local msg = 'Failed action ' .. action .. ' after ' .. attempts .. ' attempts'
    if self.log_fails then
        log:warning(msg)
    end
    if self.telemetry ~= nil then
        log:trace('Sending telemetry alert motion_fail for', action, 'max_tries')
        self.telemetry:send_alert('motion_fail', msg, {
            action = action,
            attempts = attempts,
            max_attempts = self.max_tries,
            subsystem = log.subsystem,
        })
    end
    if self.motion_fail_cb ~= nil then
        log:trace('Calling motion fail cb for', action, 'max_tries')
        self.motion_fail_cb(action, 'max_tries')
    end
end

---Broadcast an alert using telemetry for failed action due to missing fuel
---@private
---@param action string human readable name for action
function Motion:_telem_alert_no_fuel(action)
    local msg = 'Turtle is out of fuel'
    if self.log_fails then
        log:warning(msg)
    end
    if self.telemetry ~= nil then
        log:trace('Sending telemetry alert motion_fail for', action, 'no_fuel')
        self.telemetry:send_alert('no_fuel', msg, {
            action = action,
            subsystem = log.subsystem,
        })
    end
    if self.motion_fail_cb ~= nil then
        log:trace('Calling motion fail cb for', action, 'no_fuel')
        self.motion_fail_cb(action, 'no_fuel')
    end
end

---Attempt an action up to self.max_tries times
---@private
---@param action string human readable name for action
---@param action_fn function normally turtle.forward or .back or .up or .down
---@param dig_fn? function called if an attempt fails up to max attempts
---@return boolean success was the move a success
function Motion:_attempt_move(action, action_fn, dig_fn)
    local success = false
    local tries = 0
    for i = 1, self.max_tries do
        tries = i
        log:trace('Action', action, 'attempt', tries, 'of', self.max_tries)
        if action_fn() then
            log:trace('Action', action, 'was successful')
            success = true
            break
        elseif turtle.getFuelLevel() == 0 then
            log:trace('TMP FUEL STUFF')
            -- NOTE getFuelLevel can return "unlimited" if fuel consumption is disabled
            self:_telem_alert_no_fuel(action)
            return false
        elseif dig_fn ~= nil then
            log:trace('Calling dig function after fail of action', action)
            dig_fn()
        end
    end
    log:trace('Attempt to move took', tries, 'tries and was', (success and 'success' or 'fail'))
    if not success then
        self:_telem_alert_fail(action, tries)
    end
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
        if not self:_attempt_move('forward', turtle.forward, (self.can_dig and turtle.dig or nil)) then
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
        if not self:_attempt_move('back', turtle.back) then
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
        if not self:_attempt_move('up', turtle.up, (self.can_dig and turtle.digUp or nil)) then
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
        if not self:_attempt_move('down', turtle.down, (self.can_dig and turtle.digDown or nil)) then
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

---Follow a path of map points
---@param path Point[]
function Motion:follow_path(path)
    assert(#path > 1, 'Not enough points in path')
    assert(path[1]:to_vec3() == self.location.pos, 'Path does not start at current location')

    local f = fs.open('path.json', 'w')
    if f ~= nil then
        f.write(json.encode(path))
        f.close()
    end

    local actions = {}

    local last_direction = nil

    for i = 2, #path do
        local from = path[i - 1]
        local to = path[i]

        if from.x ~= to.x then
            local delta = math.abs(to.x - from.x)
            local direction = from.x < to.x and Compass.EAST or Compass.WEST
            if direction ~= last_direction then
                actions[#actions + 1] = {
                    action = 'face',
                    direction = direction,
                    direction_name = CompassName[direction],
                }
                last_direction = direction
            end
            actions[#actions + 1] = {
                action = 'forward',
                count = delta,
            }
        elseif from.y ~= to.y then
            local delta = math.abs(to.y - from.y)
            actions[#actions + 1] = {
                action = from.y < to.y and 'up' or 'down',
                count = delta,
            }
        elseif from.z ~= to.z then
            local delta = math.abs(to.z - from.z)
            local direction = from.z < to.z and Compass.SOUTH or Compass.NORTH
            if direction ~= last_direction then
                actions[#actions + 1] = {
                    action = 'face',
                    direction = direction,
                    direction_name = CompassName[direction],
                }
                last_direction = direction
            end
            actions[#actions + 1] = {
                action = 'forward',
                count = delta,
            }
        end
    end

    log:debug('Path of length', #path, 'results in', #actions, 'actions')

    f = fs.open('motion_actions.json', 'w')
    if f ~= nil then
        f.write(json.encode(actions))
        f.close()
    end

    for i, step in ipairs(actions) do
        log:trace('Step', i, 'is', step.action)
        if step.action == 'face' then
            self:face(step.direction)
        elseif step.action == 'up' then
            self:up(step.count)
        elseif step.action == 'down' then
            self:down(step.count)
        elseif step.action == 'forward' then
            self:forward(step.count)
        end
    end
end

-- ---Move to the trace step
-- ---@param step Vec3 position to move to
-- function Nav:trace_step(step)
--     log:debug('trace step to pos', step.x, step.y, step.z)
--     local pos = self.gps.pos
--     assert(is_inline(pos, step), 'Step is not inline with current position')
--     log:trace('trace starts at pos', pos.x, pos.y, pos.z)

--     if pos.x ~= step.x then
--         local delta = math.abs(step.x - pos.x)

--         if pos.x < step.x then
--             self:face(Compass.EAST)
--         else
--             self:face(Compass.WEST)
--         end

--         self.motion:forward(delta)
--     elseif pos.y ~= step.y then
--         local delta = math.abs(step.y - pos.y)

--         if pos.y < step.y then
--             self.motion:up(delta)
--         else
--             self.motion:down(delta)
--         end
--     elseif pos.z ~= step.z then
--         local delta = math.abs(step.z - pos.z)

--         if pos.z < step.z then
--             self:face(Compass.NORTH)
--         else
--             self:face(Compass.SOUTH)
--         end
--         self.motion:forward(delta)
--     end

--     local end_pos = self.gps.pos
--     local at_end_pos = end_pos.x == step.x and end_pos.y == step.y and end_pos.z == step.z

--     assert(at_end_pos, 'trace_step did not reach step position')
-- end

local M = {
    Motion = Motion,
}

return M
