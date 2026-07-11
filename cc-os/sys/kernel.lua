---@alias HookEventType string

---@alias HookFunction fun(event: HookEventType, event_data: any?)

---@class Hook
---@field pid number
---@field event HookEventType
---@field fn HookFunction

_G.kernel = {
    ---Table of event hooks by type with event type key and list of hooks value
    ---@type { [HookEventType | '*']: Hook[] }
    hooks = {},

    ---List of all processes
    ---@type Process[]
    procs = {},

    ---@type Process
    current = nil,

    ---Global PID counter
    next_pid = 1,
}
local kernel = _G.kernel

local tokenize = require 'cc-libs.util.tokenize'

local sys_proc = require 'sys.proc'
local Process = sys_proc.Process

---Clear the computer or turtle terminal and move the cursor to the start
function kernel.resetTerminal()
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

---Add a function to be called by kernel for events of a type
---@param event HookEventType event type received by kernel, use `*` to receive all events
---@param pid number process id of callback function
---@param fn HookFunction
function kernel.hook(event, pid, fn)
    -- This is the first hook for event, create the table for event hooks
    if kernel.hooks[event] == nil then
        kernel.hooks[event] = {}
    end
    -- Insert hook at the end
    table.insert(kernel.hooks[event], {
        pid = pid,
        event = event,
        fn = fn,
    })
end

---Remove a function hook added with kernel.hook
---@param event HookEventType event type for hook
---@param fn HookFunction callable passed as `fn` to kernel.hook
---@return boolean success the hook was found and removed
function kernel.unhook(event, fn)
    -- No hooks exist for event
    if kernel.hooks[event] == nil then
        return false
    end
    for i, v in ipairs(kernel.hooks[event]) do
        -- Match the callable fn
        if v == fn then
            table.remove(kernel.hooks, i)
            return true
        end
    end
    return false
end

---Load and run a load a lua script. This function does not wait for the process
---@param path string path to lua file
---@param args string[] arguments to the script
---@param parent_pid number pid of the parent process
---@return Process? proc the new process object
---@return string? err
function kernel.run(path, args, parent_pid)
    -- TODO replace with kernel logging when that's created
    -- print('run', path)

    -- Create new env for script
    local env = setmetatable({}, { __index = _ENV })

    -- Load the lua script
    local fn, err = loadfile(path, nil, env)
    if not fn then
        return nil, err
    end

    -- Create new process for fn with pid and env
    local p = Process:new(path, { path, table.unpack(args) }, fn, env, parent_pid)
    kernel.procs[p.pid] = p

    -- Launch the process
    local success
    success, err = p:send_event('start')
    if not success then
        -- TODO unhook process

        p:cleanup()
        kernel.procs[p.pid] = nil

        -- TODO maybe replace with kernel logging when that's created
        print('Failed to launch process', path, err)
        -- error(err)
    end

    return p
end

---Load and run a load a lua script. This function does not wait for the process
---@param cmd string command and args as a single string
---@return Process? proc the new process object
---@return string? err
function kernel.exec(cmd)
    local args = tokenize(cmd)
    -- Create new env for script
    local env = setmetatable({}, { __index = _ENV })

    -- Load the lua script
    local fn, err = loadfile(path, nil, env)
    if not fn then
        return nil, err
    end

    -- Create new process for fn with pid and env
    local p = Process:new(path, { path, table.unpack(args) }, fn, env, parent_pid)
    kernel.procs[p.pid] = p

    -- Launch the process
    local success
    success, err = p:send_event('start')
    if not success then
        -- TODO unhook process

        p:cleanup()
        kernel.procs[p.pid] = nil

        -- TODO maybe replace with kernel logging when that's created
        print('Failed to launch process', path, err)
        -- error(err)
    end

    return p
end

---Get the Process for a given pid
---@param pid number process id
---@return Process? process
function kernel.get_pid(pid)
    for _, proc in ipairs(kernel.procs) do
        if proc.pid == pid then
            return proc
        end
    end
end

---Get the Process for a given coroutine thread
---@param co thread coroutine thread
---@return Process? process
function kernel.get_co(co)
    for _, proc in ipairs(kernel.procs) do
        if proc.co == co then
            return proc
        end
    end
end

---Pass an event to the kernel. This will be propagated to hooks and process'
---@param event HookEventType event type
---@param event_data any? event data
function kernel.event(event, event_data)
    -- Call hooks that process all events
    local hooks = kernel.hooks['*']
    if hooks then
        for _, h in ipairs(hooks) do
            h.fn(event, event_data)
        end
    end

    -- Call hooks that process this event
    hooks = kernel.hooks[event]
    if hooks then
        for _, fn in ipairs(hooks) do
            fn(event, event_data)
        end
    end

    for _, proc in ipairs(kernel.procs) do
        if proc:alive() and not proc.filter or proc.filter == event then
            proc:send_event(event, event_data)
        end
    end

    kernel.prune_dead()
end

---Remove dead processes
---@return number[] pids list of process ids that were removed
function kernel.prune_dead()
    -- Keep as separate list of processes to remove for iteration safety after removal
    local to_prune = {}

    -- Get list of dead processes
    for _, proc in ipairs(kernel.procs) do
        if not proc:alive() then
            table.insert(to_prune, proc.pid)
        end
    end

    -- Remove dead processes
    for _, pid in ipairs(to_prune) do
        -- Find and remove process for pid
        for i, proc in ipairs(kernel.procs) do
            if proc.pid == pid then
                proc:cleanup()
                table.remove(kernel.procs, i)
                break
            end
        end
    end

    return to_prune
end

local function main()
    kernel.resetTerminal()

    -- TODO can cc shell and other apps work?
    -- kernel.run('/sys/app/telemetry.lua')
    -- kernel.run('/sys/app/keyboy.lua')
    kernel.run('/sys/app/shell.lua', {}, 0)

    -- kernel.run('rom/programs/shell.lua')

    -- TODO is any more logic needed for task switching?
    repeat
        local eventData = { os.pullEventRaw() }
        local event = table.remove(eventData, 1)
        kernel.event(event, eventData)
        if #kernel.procs == 0 then
            print('All processes exited')
            break
        end
    until event == 'terminate'
    if term.isColour() then
        term.setTextColour(colors.cyan)
    end
    print('Goodbye')
    term.setTextColour(colors.white)
    sleep(1)
    print('WOULD SHUTDOWN')
    -- os.shutdown()
end

main()
