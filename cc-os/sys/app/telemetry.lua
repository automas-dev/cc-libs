while true do
    local event = os.pullEvent()
    if event[1] == 'char' then
        print('telem', event[1])
    end
end
