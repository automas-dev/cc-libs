-- error('yea')

_G.kernel = {}

function _G.kernel.resetTerminal()
    term.clear()
    term.setCursorPos(1, 1)
    term.setCursorBlink(false)
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
end

kernel.resetTerminal()
print('start')

while true do
    local event = { os.pullEventRaw() }
    print('event', event[1])
    if event[1] == 'terminate' then
        print('Kernel got a terminate signal')
        return
    end
end
