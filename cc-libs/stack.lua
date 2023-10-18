local stack = {}

function stack:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function stack:push(e)
    self[#self + 1] = e
end

function stack:pop()
    if #self > 0 then
        return table.remove(self, #self)
    end
end

function stack:peek()
    if #self > 0 then
        return self[#self]
    end
end

return stack
