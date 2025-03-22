repeat
    local event, event_data = os.pullEvent('key')
    if event == 'key' then
        local key, held = table.unpack(event_data)
        if not held then
            print(key, '=', keys.getName(key))
            -- if key == keys.e then
            --     print('Event')
            --     os.queueEvent('telem')
            -- end
        end
    end
until event == 'kill'
