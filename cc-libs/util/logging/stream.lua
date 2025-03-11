---@class Stream
---@field level number|LogLevel minimum message level
---@field send fun(self: Stream, message: string): boolean

local REDNET_PROTOCOL = 'remote_log'

---@class ConsoleStream : Stream
local ConsoleStream = {}

---Create a new ConsoleStream instance
---@param level? number|LogLevel stream level or default 0
---@return ConsoleStream
function ConsoleStream:new(level)
    local o = {
        level = level or 0,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Write the message to print
---@param message string the log message as a single string
---@return boolean success was the message send successful
function ConsoleStream:send(message)
    print(message)
    return true
end

---@class FileStream : Stream
---@field filename string
---@field file? file*
local FileStream = {}

---Create a new FileStream instance
---@param filename string path to the log file, opened in first call to send
---@param level? number|LogLevel stream level or default 0
---@return FileStream
function FileStream:new(filename, level)
    assert(filename ~= nil, 'filename must not be nil')
    local o = {
        filename = filename,
        level = level or 0,
        file = nil,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@param filename string
---@return boolean success was the file opened
---@return string? error error message if success is false
function FileStream:open_file(filename)
    -- Close any open file
    if self.file ~= nil then
        self.file:close()
        self.file = nil
    end

    -- Open the file in append mode
    local file, err = io.open(filename, 'a')
    if file then
        self.file = file
        return true
    else
        print('Error opening log file: ' .. err)
        return false, err
    end
end

---Write the message to the open file. Open a file if one is not yet open.
---@param message string the log message as a single string
---@return boolean success was the message send successful
function FileStream:send(message)
    if self.file == nil and not self:open_file(self.filename) then
        return false
    end
    self.file:write(message)
    self.file:write('\n')
    self.file:flush()
    return true
end

---@class RemoteStream : Stream
local RemoteStream = {}

---Create a new RemoteStream instance
---@param level? number|LogLevel stream level or default 0
---@return RemoteStream
function RemoteStream:new(level)
    local o = {
        level = level or 0,
    }
    setmetatable(o, self)
    self.__index = self
    peripheral.find('modem', rednet.open)
    return o
end

---Write the message to the open file. Open a file if one is not yet open.
---@param message string the log message as a single string
---@return boolean success was the message send successful
function RemoteStream:send(message)
    rednet.broadcast(message, REDNET_PROTOCOL)
    return true
end

return {
    ConsoleStream = ConsoleStream,
    FileStream = FileStream,
    RemoteStream = RemoteStream,
}
