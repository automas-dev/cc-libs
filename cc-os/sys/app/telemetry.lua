repeat
    local event, event_data = os.pullEvent('telem')
    if event == 'telem' then
        print('Telemetry got', event_data)
    end
until event == 'kill'
