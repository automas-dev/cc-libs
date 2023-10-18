local queue = {}

function queue:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function queue:push(e)
    self[#self + 1] = e
end

function queue:pop()
    if #self > 0 then
        return table.remove(self, 1)
    end
end

return queue
