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
    _file = nil,
}

function M.open_file(path)
    -- Close any open file
    if M._file ~= nil then
        M._file:close()
        M._file = nil
    end

    -- Open the file in append mode
    file, err = io.open(path, 'a')
    if file then
        M._file = file
    else
        print('Error opening log file: ' .. err)
    end
end

function M.log(msg, level)
    assert(level ~= nil, 'level cannot be nil')
    if level >= M.print_level then
        print(msg)
    end

    if level >= M.level and M.file ~= nil then
        if M._file == nil then
            M.open_file(M.file)
        end

        if M.file then
            if M._file then
                local text = '[' .. timestamp() .. '] ' .. msg .. '\n'
                file:write(text)
                file:flush()
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
