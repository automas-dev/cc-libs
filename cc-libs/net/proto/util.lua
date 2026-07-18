local function open_rednet()
    if not rednet.isOpen() then
        peripheral.find('modem', rednet.open)
    end
end

return {
    open_rednet = open_rednet,
}
