package.path = '../?.lua;../?/init.lua;' .. package.path

peripheral.find('modem', rednet.open)

while true do
    local id, message = rednet.receive('remote_log')
    print('Got message from ' .. id .. ': ' .. message)
end
