local Levels = {
    trace = 0,
    debug = 1,
    info = 2,
    warning = 3,
    error = 4,
    fatal = 5,
}

local function level_name(level)
    assert(level >= 0, 'level must be a positive number')
    if level == Levels.trace then return 'trace'
    elseif level == Levels.debug then return 'debug'
    elseif level == Levels.info then return 'info'
    elseif level == Levels.warning then return 'warning'
    elseif level == Levels.error then return 'error'
    elseif level == Levels.fatal then return 'fatal'
    else return 'custom:' .. tostring(level)
    end
end

local function timestamp()
    return os.date('%Y-%m-%dT%H:%M:%S')
end

local M = {
    Levels = Levels,
    level_name = level_name,
    level = Levels.info,
    file_level = nil,
    file = nil,
}

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

M.Core = M:new('Core')

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
        local long_msg = '[' .. timestamp() .. '] [' .. self.subsystem .. '] [' .. level_name(level) .. '] ' .. get_msg()
        local file, err = io.open(M.file, 'a')
        if file then
            file:write(long_msg .. '\n')
            file:close()
        else
            print('Error writing to log file: ' .. err)
        end
    end
end

function M:trace(...)
    self:log(Levels.trace, ...)
end

function M:debug(...)
    self:log(Levels.debug, ...)
end

function M:info(...)
    self:log(Levels.info, ...)
end

function M:warn(...)
    self:log(Levels.warning, ...)
end

function M:error(...)
    self:log(Levels.error, ...)
end

function M:fatal(...)
    self:log(Levels.fatal, ...)
    error()
end

return M
