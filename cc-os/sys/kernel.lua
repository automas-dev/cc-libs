_G.kernel = {
    hooks = {},
    procs = {},
}
local kernel = _G.kernel

local proc = require 'sys.proc'
local Process = proc.Process

local next_pid = 1

function kernel.resetTerminal()
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

function kernel.hook(event, pid, fn)
    if kernel.hooks[event] == nil then
        kernel.hooks[event] = {}
    end
    local h = table.insert(kernel.hooks[event], {
        pid = pid,
        event = event,
        fn = fn,
    })
    return h
end

function kernel.unhook(event, fn)
    if kernel.hooks[event] == nil then
        return
    end
    for i, v in ipairs(kernel.hooks[event]) do
        if v == fn then
            table.remove(kernel.hooks, i)
            return
        end
    end
end

function kernel.run(path)
    print('run', path)
    local env = setmetatable({}, { __index = _ENV })
    local fn, err = loadfile(path, nil, env)
    if fn then
        local p = Process:new(next_pid, fn, env)
        kernel.procs[p.pid] = p
        next_pid = next_pid + 1
        kernel.current = p
        local success, err = p:resume('start')
        if not success then
            print('Failed to launch process', path, err)
            error(err)
            -- TODO unhook process
            -- kernel.procs[p.pid] = nil
            table.remove(kernel.procs, #kernel.procs)
        end
    else
        error(err)
    end
end

function kernel.event(event, event_data)
    local hooks = kernel.hooks['*']
    if hooks then
        for _, fn in ipairs(hooks) do
            fn(event, event_data)
        end
    end
    hooks = kernel.hooks[event]
    if hooks then
        for _, fn in ipairs(hooks) do
            fn(event, event_data)
        end
    end

    local to_prune = {}

    for _, proc in pairs(kernel.procs) do
        if coroutine.status(proc.co) == 'dead' then
            table.insert(to_prune, proc.pid)
        end
    end

    for _, pid in ipairs(to_prune) do
        for i, h in ipairs(kernel.hooks) do
            if h.pid == pid then
                table
            end
        end
    end
end

kernel.resetTerminal()
print('start')

kernel.run('/sys/app/telemetry.lua')
-- kernel.run('/sys/app/keyboy.lua')
kernel.run('/sys/app/shell.lua')

repeat
    local eventData = { os.pullEventRaw() }
    local event = table.remove(eventData, 1)
    kernel.event(event, eventData)
until event == 'terminate'
