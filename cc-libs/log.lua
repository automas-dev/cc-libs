local levels = {
    debug = 0,
    info = 1,
    warning = 2,
    error = 3
}

local function timestamp()
    return os.date('%Y-%m-%dT%H:%M:%S')
end

local M = {
    levels = levels,
    level = levels.warning,
    print_level = levels.info,
    file = nil,
}

function M.log(msg, level)
    assert(level ~= nil, 'level cannot be nil')
    if level >= M.print_level then
        print(msg)
    end

    if level >= M.level then
        local text = '[' .. timestamp() .. '] ' .. msg .. '\n'
        if M.file then
            file, err = io.open(M.file, 'a')
            if file then
                file:write(text)
                file:close()
            else
                print('Error writing to log file: ' .. err)
            end
        end
    end
end

function M.debug(msg)
    M.log('D: ' .. msg, levels.debug)
end

function M.info(msg)
    M.log('I: ' .. msg, levels.info)
end

function M.warn(msg)
    M.log('W: ' .. msg, levels.warning)
end

function M.error(msg)
    M.log('E: ' .. msg, levels.error)
end

function M.fatal(msg)
    M.log('E: ' .. msg, levels.error)
    error()
end

return M
