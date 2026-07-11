local tokenize = require 'cc-libs.util.tokenize'

-- local special_map = {
--     -- [keys.semicolon] = ';', -- idk why this doesn't work, using hard coded 39
--     [39] = ';',
--     [keys.apostrophe] = "'",
--     [keys.backslash] = '\\',
--     [keys.comma] = ',',
--     [keys.period] = '.',
--     [keys.slash] = '/',
--     [keys.minus] = '-',
--     [keys.equals] = '=',
--     [keys.grave] = '`',
--     [keys.leftBracket] = '[',
--     [keys.rightBracket] = ']',
--     [keys.zero] = '0',
--     [keys.one] = '1',
--     [keys.two] = '2',
--     [keys.three] = '3',
--     [keys.four] = '4',
--     [keys.five] = '5',
--     [keys.six] = '6',
--     [keys.seven] = '7',
--     [keys.eight] = '8',
--     [keys.nine] = '9',
-- }

-- local shift_special_map = {
--     -- [keys.semicolon] = ':', -- idk why this doesn't work, using hard coded 39
--     [39] = ':',
--     [keys.apostrophe] = '"',
--     [keys.backslash] = '|',
--     [keys.comma] = '<',
--     [keys.period] = '>',
--     [keys.slash] = '?',
--     [keys.minus] = '_',
--     [keys.equals] = '+',
--     [keys.grave] = '~',
--     [keys.one] = '!',
--     [keys.two] = '@',
--     [keys.three] = '#',
--     [keys.four] = '$',
--     [keys.five] = '%',
--     [keys.six] = '^',
--     [keys.seven] = '&',
--     [keys.eight] = '*',
--     [keys.nine] = '(',
--     [keys.zero] = ')',
--     [keys.leftBracket] = '{',
--     [keys.rightBracket] = '}',
-- }

-- local function is_alpha(c)
--     return string.gmatch(c, '^[a-zA-Z]$')
-- end

local search_path = '/:/sys/app'

local buff = {}

local should_exit = false

local shell_builtin = {
    -- read = function()
    --     print('read is', read)
    --     local r = read()
    --     print(type(r))
    --     print(r)
    -- end,

    exit = function()
        print('Should exit')
        should_exit = true
    end,

    proc = function()
        ---@type Process
        ---@diagnostic disable-next-line: undefined-field
        local p = os.getCurrentProcess()
        print('pid =', p.pid, 'parent =', p.parent)
        print('cpu_time =', p.time, 'wall_clock =', p:age())
        print('filename =', p.filename)
        print('cmd =', p.cmd)
    end,

    host = function()
        local child = os.popen('/sys/app/hostname.lua')
        print('Child is', child)
    end,

    pwd = function()
        print(os.getCwd())
    end,

    cd = function(path)
        os.chdir(path[2])
    end,
}

function shell_builtin.help()
    for cmd, _ in pairs(shell_builtin) do
        print(cmd)
    end
end

local function run_cmd(cmd)
    term.setCursorBlink(false)
    local args = tokenize(cmd, ' ', true)
    if #args == 0 then
        print('empty')
        return false
    end
    local fn = shell_builtin[args[1]]
    if fn then
        fn(args)
        return true
    end
    local pid = os.popen(cmd)
    if pid ~= nil then
        os.waitPid(pid)
    else
        term.setTextColor(colors.magenta)
        print('Command', cmd, 'not found')
    end
end

local function write_prompt()
    if should_exit then
        return
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.lime)
    write('> ')
    term.setTextColor(colors.white)
    term.setCursorBlink(true)
end

local function run_buff()
    local cmd = ''
    while #buff > 0 do
        local c = table.remove(buff, 1)
        if c == '\n' then
            if #cmd > 0 then
                run_cmd(cmd)
            end
            cmd = ''
        else
            cmd = cmd .. c
        end
    end
    if #cmd > 0 then
        run_cmd(cmd)
    end
    write_prompt()
end

local function add_char(c)
    table.insert(buff, c)
    write(c)
end

local function handle_ctrl_key(key)
    if key == keys.c then
        buff = {}
        print('^C')
        write_prompt()
    end
end

write_prompt()

-- local shift_held = 0
local ctrl_held = 0

repeat
    local event, event_data = os.pullEvent()
    -- print('Got event', event)
    if event == 'char' then
        local c = table.unpack(event_data)
        add_char(c)
    elseif event == 'key' then
        local key, held = table.unpack(event_data)
        local key_name = keys.getName(key)
        -- if key == keys.leftShift or key == keys.rightShift then
        --     shift_held = shift_held + 1
        -- elseif shift_held > 0 and shift_special_map[key] ~= nil then
        --     add_char(shift_special_map[key])
        -- elseif special_map[key] ~= nil then
        --     add_char(special_map[key])
        -- elseif key_name and #key_name == 1 then
        --     if is_alpha(key_name) and shift_held > 0 then
        --         key_name = key_name:upper()
        --     end
        --     add_char(key_name)
        -- elseif key == keys.space then
        --     add_char(' ')
        if key == keys.leftCtrl or key == keys.rightCtrl then
            ctrl_held = ctrl_held + 1
        elseif ctrl_held > 0 then
            handle_ctrl_key(key)
        elseif key == keys.enter and not held then
            add_char('\n')
            run_buff()
        elseif key == keys.backspace then
            if #buff > 0 then
                table.remove(buff, #buff)
                local x, y = term.getCursorPos()
                if x == 1 then
                    local width = term.getSize()
                    x = width
                    y = y - 1
                    term.setCursorPos(x, y)
                    write(' ')
                    term.setCursorPos(x, y)
                else
                    term.setCursorPos(x - 1, y)
                    write(' ')
                    term.setCursorPos(x - 1, y)
                end
                -- write('\b')
            end
            -- table.remove()
        end
        -- if key == keys.e then
        --     print('Event')
        --     os.queueEvent('telem')
        -- end
    elseif event == 'key_up' then
        local key = table.unpack(event_data)
        if key == keys.leftCtrl or key == keys.rightCtrl then
            ctrl_held = ctrl_held - 1
            -- elseif key == keys.leftShift or key == keys.rightShift then
            --     shift_held = shift_held - 1
        end
    end
until event == 'kill' or should_exit
