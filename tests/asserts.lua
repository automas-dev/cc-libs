local float_error = 0.00001

---Expect that a value evaluates to true.
---@param val any
---@param msg? string optional failure message
function expect_true(val, msg)
    if not val then
        local error_msg = 'expect failed (' .. tostring(val) .. ') was false'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            value = val,
        })
    end
end

---Expect that a value evaluates to false.
---@param val any
---@param msg? string optional failure message
function expect_false(val, msg)
    if val then
        local error_msg = 'expect failed (' .. tostring(val) .. ') was true'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            value = val,
        })
    end
end

---Expect that two values are equal.
---@param lhs any
---@param rhs any
---@param msg? string optional failure message
function expect_eq(lhs, rhs, msg)
    if lhs ~= rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that two values are not equal.
---@param lhs any
---@param rhs any
---@param msg? string optional failure message
function expect_ne(lhs, rhs, msg)
    if lhs == rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that two floating-point values are equal using a tolerance.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_float_eq(lhs, rhs, msg)
    if math.abs(lhs - rhs) > float_error then
        local error_msg = 'expect failed float (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that two floating-point values are not equal using a tolerance.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_float_ne(lhs, rhs, msg)
    if math.abs(lhs - rhs) <= float_error then
        local error_msg = 'expect failed float (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that `lhs` is greater than `rhs`.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_gt(lhs, rhs, msg)
    if lhs <= rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') <= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that `lhs` is greater than or equal to `rhs`.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_ge(lhs, rhs, msg)
    if lhs < rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') < (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that `lhs` is less than `rhs`.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_lt(lhs, rhs, msg)
    if lhs >= rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') >= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Expect that `lhs` is less than or equal to `rhs`.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function expect_le(lhs, rhs, msg)
    if lhs > rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') > (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

---Assert that a value evaluates to true.
---The test case stops execution if this assertion fails.
---@param val any
---@param msg? string optional failure message
function assert_true(val, msg)
    if not val then
        local error_msg = 'assert failed (' .. tostring(val) .. ') was false'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            value = val,
        })
        error({ type = 'test assert' })
    end
end

---Assert that a value evaluates to false.
---The test case stops execution if this assertion fails.
---@param val any
---@param msg? string optional failure message
function assert_false(val, msg)
    if val then
        local error_msg = 'assert failed (' .. tostring(val) .. ') was true'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            value = val,
        })
        error({ type = 'test assert' })
    end
end

---Assert that two values are equal.
---The test case stops execution if this assertion fails.
---@param lhs any
---@param rhs any
---@param msg? string optional failure message
function assert_eq(lhs, rhs, msg)
    if lhs ~= rhs then
        local error_msg = 'assert failed (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that two values are not equal.
---The test case stops execution if this assertion fails.
---@param lhs any
---@param rhs any
---@param msg? string optional failure message
function assert_ne(lhs, rhs, msg)
    if lhs == rhs then
        local error_msg = 'assert failed (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that two floating-point values are equal using a tolerance.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_float_eq(lhs, rhs, msg)
    if math.abs(lhs - rhs) > float_error then
        local error_msg = 'assert failed float (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that two floating-point values are not equal using a tolerance.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_float_ne(lhs, rhs, msg)
    if math.abs(lhs - rhs) <= float_error then
        local error_msg = 'assert failed float (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that `lhs` is greater than `rhs`.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_gt(lhs, rhs, msg)
    if lhs <= rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') <= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that `lhs` is greater than or equal to `rhs`.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_ge(lhs, rhs, msg)
    if lhs < rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') < (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that `lhs` is less than `rhs`.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_lt(lhs, rhs, msg)
    if lhs >= rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') >= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end

---Assert that `lhs` is less than or equal to `rhs`.
---The test case stops execution if this assertion fails.
---@param lhs number
---@param rhs number
---@param msg? string optional failure message
function assert_le(lhs, rhs, msg)
    if lhs > rhs then
        local error_msg = 'expect failed (' .. tostring(lhs) .. ') > (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
        error({ type = 'test assert' })
    end
end
