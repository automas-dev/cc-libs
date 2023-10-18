local Levels = {
    trace = 0,
    debug = 1,
    info = 2,
    warning = 3,
    error = 4,
    fatal = 5,
}

--- Get the string representation of a level
-- @param level the level number
local function level_name(level)
    assert(level >= 0, 'level must be a positive number')
    if level == Levels.trace then
        return 'trace'
    elseif level == Levels.debug then
        return 'debug'
    elseif level == Levels.info then
        return 'info'
    elseif level == Levels.warning then
        return 'warning'
    elseif level == Levels.error then
        return 'error'
    elseif level == Levels.fatal then
        return 'fatal'
    else
        return 'custom:' .. tostring(level)
    end
end

--- Get a string timestamp for the current time
local function timestamp()
    return os.date('%Y-%m-%dT%H:%M:%S')
end

--- Module
local M = {
    Levels = Levels,
    level_name = level_name,
    level = Levels.info,
    file_level = nil,
    file = nil,
    _file = nil,
}

--- Create a new logger for the given subsystem with print and file log levels
-- @param subsystem the subsystem name
-- @param level the print log level
-- @param file_level the file log level
function M:new(subsystem, level, file_level)
    local o = {
        subsystem = subsystem or 'undefined',
        level = level,
        file_level = file_level,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Open a log file
-- @param path the log file path
function M.open_file(path)
    -- Close any open file
    if M._file ~= nil then
        M._file:close()
        M._file = nil
    end

    -- Open the file in append mode
    local file, err = io.open(path, 'a')
    if file then
        M._file = file
    else
        print('Error opening log file: ' .. err)
    end
end

--- Write a log message with level
-- @param level the message level
-- @param ... the message
function M:log(level, ...)
    assert(level ~= nil, 'level cannot be nil')
    local args = { ... }

    local msg = nil
    local function get_msg()
        if msg then return msg end
        msg = ''
        for i = 1, #args do
            if i == 1 then
                msg = tostring(args[1])
            else
                msg = msg .. ' ' .. tostring(args[i])
            end
        end
        return msg
    end

    if level >= (self.level or M.level) then
        local short_msg = '[' .. self.subsystem .. '] ' .. get_msg()
        print(short_msg)
    end

    if M.file and level >= (self.file_level or self.level or M.file_level or M.level) then
        if M._file == nil then
            M.open_file(M.file)
        end

        if M._file then
            local long_msg = '['
                .. timestamp()
                .. '] ['
                .. self.subsystem
                .. '] ['
                .. level_name(level)
                .. '] '
                .. get_msg()
            M._file:write(long_msg .. '\n')
            M._file:flush()
        end
    end
end

--- Write a log message with trace level
-- @param ... the message
function M:trace(...)
    self:log(Levels.trace, ...)
end

--- Write a log message with debug level
-- @param ... the message
function M:debug(...)
    self:log(Levels.debug, ...)
end

--- Write a log message with info level
-- @param ... the message
function M:info(...)
    self:log(Levels.info, ...)
end

--- Write a log message with warn level
-- @param ... the message
function M:warn(...)
    self:log(Levels.warning, ...)
end

--- Write a log message with error level
-- @param ... the message
function M:error(...)
    self:log(Levels.error, ...)
end

--- Write a log message with error level and call error()
-- @param ... the message
function M:fatal(...)
    self:log(Levels.fatal, ...)
    error()
end

-- Create default Core logger
M.Core = M:new('Core')

return M
