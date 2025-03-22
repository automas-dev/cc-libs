local kernel = _G.kernel

local special_map = {
    -- [keys.semicolon] = ';', -- idk why this doesn't work, using hard coded 39
    [39] = ';',
    [keys.apostrophe] = "'",
    [keys.backslash] = '\\',
    [keys.comma] = ',',
    [keys.period] = '.',
    [keys.slash] = '/',
    [keys.minus] = '-',
    [keys.equals] = '=',
    [keys.grave] = '`',
    [keys.leftBracket] = '[',
    [keys.rightBracket] = ']',
    [keys.zero] = '0',
    [keys.one] = '1',
    [keys.two] = '2',
    [keys.three] = '3',
    [keys.four] = '4',
    [keys.five] = '5',
    [keys.six] = '6',
    [keys.seven] = '7',
    [keys.eight] = '8',
    [keys.nine] = '9',
}
print('start')

local shift_special_map = {
    -- [keys.semicolon] = ':', -- idk why this doesn't work, using hard coded 39
    [39] = ':',
    [keys.apostrophe] = '"',
    [keys.backslash] = '|',
    [keys.comma] = '<',
    [keys.period] = '>',
    [keys.slash] = '?',
    [keys.minus] = '_',
    [keys.equals] = '+',
    [keys.grave] = '~',
    [keys.one] = '!',
    [keys.two] = '@',
    [keys.three] = '#',
    [keys.four] = '$',
    [keys.five] = '%',
    [keys.six] = '^',
    [keys.seven] = '&',
    [keys.eight] = '*',
    [keys.nine] = '(',
    [keys.zero] = ')',
    [keys.leftBracket] = '{',
    [keys.rightBracket] = '}',
}

local function is_alpha(c)
    return string.gmatch(c, '^[a-zA-Z]$')
end

local buff = {}

local function run_cmd(cmd)
    term.setCursorBlink(false)
    kernel.run(cmd)
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
    write('> ')
end

local function add_char(c)
    table.insert(buff, c)
    write(c)
end

write('> ')
term.setCursorBlink(true)

local shift_held = 0

repeat
    local event, event_data = os.pullEvent()
    if event == 'key' then
        local key, held = table.unpack(event_data)
        if not held then
            local key_name = keys.getName(key)
            if key == keys.leftShift or key == keys.rightShift then
                shift_held = shift_held + 1
            elseif shift_held > 0 and shift_special_map[key] ~= nil then
                add_char(shift_special_map[key])
            elseif special_map[key] ~= nil then
                add_char(special_map[key])
            elseif key_name and #key_name == 1 then
                if is_alpha(key_name) and shift_held > 0 then
                    key_name = key_name:upper()
                end
                add_char(key_name)
            elseif key == keys.space then
                add_char(' ')
            elseif key == keys.enter then
                add_char('\n')
                run_buff()
            elseif key == keys.backspace then
                if #buff > 0 then
                    table.remove(buff, #buff)
                    write('\b')
                end
                -- table.remove()
            end
            -- if key == keys.e then
            --     print('Event')
            --     os.queueEvent('telem')
            -- end
        end
    elseif event == 'key_up' then
        local key = table.unpack(event_data)
        if key == keys.leftShift or key == keys.rightShift then
            shift_held = shift_held - 1
        end
    end
until event == 'kill'
