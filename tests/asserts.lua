local float_error = 0.00001

function assert_true(val, msg)
    if not val then
        local error_msg = 'assert failed (' .. tostring(val) .. ') was false'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            value = val,
        })
    end
end

function assert_false(val, msg)
    if val then
        local error_msg = 'assert failed (' .. tostring(val) .. ') was true'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            value = val,
        })
    end
end

function assert_eq(lhs, rhs, msg)
    if lhs ~= rhs then
        local error_msg = 'assert failed (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

function assert_ne(lhs, rhs, msg)
    if lhs ~= rhs then
        local error_msg = 'assert failed (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

function assert_float_eq(lhs, rhs, msg)
    if math.abs(lhs - rhs) > float_error then
        local error_msg = 'assert failed float (' .. tostring(lhs) .. ') ~= (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end

function assert_float_ne(lhs, rhs, msg)
    if math.abs(lhs - rhs) <= float_error then
        local error_msg = 'assert failed float (' .. tostring(lhs) .. ') == (' .. tostring(rhs) .. ')'
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        error({
            msg = error_msg,
            lhs = lhs,
            rhs = rhs,
        })
    end
end
