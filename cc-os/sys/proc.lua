-- Get a local reference to make type checks happy
local kernel = _G.kernel

local ccl_path = require 'cc-libs.util.path'

---@class Process
---@field pid number process id
---@field parent number pid of the parent process
---@field filename string lua file this process was loaded from
---@field cmd string command line that executed this program
---@field created number process creation time in seconds
---@field co thread
---@field env table
---@field filter string? specify event type to be received from the kernel
---@field filter_data? any extra data for filter
---@field exit_code number? exit code after process dies
local Process = {}

---@param filename string lua file this process was loaded from
---@param cmd string[] command line that executed this program
---@param f fun()
---@param env table
---@param parent_pid number pid of the parent process
---@return Process
function Process:new(filename, cmd, f, env, parent_pid)
    local o = {
        -- TODO parent
        parent = parent_pid,
        pid = kernel.next_pid,
        filename = filename,
        cmd = cmd,
        cwd = '/',
        created = os.clock(),
        co = coroutine.create(f),
        env = env,
        time = 0,
        hooks = {},
        -- TODO implement this
        exit_code = nil,
    }
    setmetatable(o, self)
    self.__index = self

    env.os.pullEvent = function(event)
        return coroutine.yield(event)
    end
    env.os.pullEventRaw = os.pullEvent

    -- Get the current PID from within the process
    env.os.getPid = function()
        return o.pid
    end

    env.os.getCurrentProcess = function()
        return o
    end

    -- Get this process struct from within the process
    env.os.getProcess = function(pid)
        return kernel.get_pid(pid)
    end

    env.os.popen = function(proc_cmd)
        local filt, child = coroutine.yield('popen', proc_cmd)
        assert(filt == 'popen')
        return child
    end

    env.os.waitPid = function(pid)
        coroutine.yield('wait_pid', pid)
    end

    env.os.getCwd = function()
        return o.cwd
    end

    env.os.chdir = function(path)
        if path == nil or #path == 0 then
            return false
        end
        local new_path = ccl_path.resolve(path, o.cwd)
        o.cwd = new_path
    end

    kernel.next_pid = kernel.next_pid + 1

    return o
end

function Process:cleanup()
    -- print('Cleanup', self.pid)
end

---Get the process age in seconds
---@return number age time since creation in seconds
function Process:age()
    return os.clock() - self.created
end

---Process is not dead
---@return boolean alive
function Process:alive()
    return coroutine.status(self.co) ~= 'dead'
end

---Resume execution of this process with an event and optional data
---@param event string event type
---@param event_data any? event data
---@param ... any
---@return boolean success there were no errors
---@return string? filter filter from os.pullEvent
---@return any ...
function Process:send_event(event, event_data, ...)
    if not self:alive() then
        error('Process ' .. self.pid .. ' is already dead')
    end

    if not self.filter or self.filter == event or event == 'terminate' then
        if self.filter == 'wait_pid' then
            local pid = event_data
            if pid ~= self.filter_data then
                return true
            end
        end

        local start_time = os.clock()

        kernel.current = self
        -- Yield is called from os.pullEvent, so resume will only receive two results
        local success, res, data = coroutine.resume(self.co, event, event_data)

        -- Keep track of process execution duration
        local end_time = os.clock()
        self.time = self.time + (end_time - start_time)

        -- Handle errors in the process
        if not success then
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.red)
            print('Process', self.pid, 'crashed', res)
            term.setTextColor(colors.white)
            return false
        end

        -- Handle process exiting normally
        if not self:alive() then
            return true
        end

        -- Handle yield
        local filter = res
        -- Assign new filter for events from kernel
        self.filter = filter
        self.filter_data = data

        if filter == 'popen' then
            self.filter_data = nil
            local pid = nil
            local child = kernel.run(data, self.pid)
            if child then
                pid = child.pid
            end
            self:send_event(filter, pid)
            return true, nil
        end

        return true, filter
    end

    return true
end

return {
    Process = Process,
}
