function expect_arr_eq(lhs, rhs, msg)
    if #lhs ~= #rhs then
        local error_msg = 'expect failed length ' .. #lhs .. ' ~= ' .. #rhs
        if msg then
            error_msg = error_msg .. '\n  ' .. msg
        end
        store_check_fail({
            msg = error_msg,
            lhs = #lhs,
            rhs = #rhs,
        })
        return
    end
    for i = 1, #lhs do
        if lhs[i] ~= rhs[i] then
            local error_msg = 'expect failed at index ' .. i .. ' ' .. lhs[i] .. ' ~= ' .. rhs[i]
            if msg then
                error_msg = error_msg .. '\n  ' .. msg
            end
            store_check_fail({
                msg = error_msg,
                lhs = lhs,
                rhs = rhs,
                index = i,
            })
            return
        end
    end
end
