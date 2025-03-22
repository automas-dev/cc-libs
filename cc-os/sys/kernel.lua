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

function kernel.hook(event, fn)
    if kernel.hooks[event] == nil then
        kernel.hooks[event] = {}
    end
    table.insert(kernel.hooks[event], fn)
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
    local env = setmetatable({}, { __index = _ENV })
    local fn, err = loadfile(path, nil, env)
    if fn then
        local p = Process:new(next_pid, fn, env)
        table.insert(_G.kernel.procs, p)
        next_pid = next_pid + 1
        kernel.current = p
        p:resume('start')
    else
        error(err)
    end

    kernel.current:resume()
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
end

kernel.resetTerminal()
print('start')

kernel.run('/sys/app/telemetry.lua')
kernel.run('/sys/app/keyboy.lua')

repeat
    local eventData = { os.pullEventRaw() }
    local event = table.remove(eventData, 1)
    kernel.event(event, eventData)
until event == 'terminate'
