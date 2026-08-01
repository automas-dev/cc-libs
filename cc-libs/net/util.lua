---Open all modems with rednet that are not already open.
---@return boolean open at least one modem is open with rednet
local function open_rednet()
    return rednet.isOpen() or peripheral.find('modem', rednet.open) ~= nil
end

return {
    open_rednet = open_rednet,
}
