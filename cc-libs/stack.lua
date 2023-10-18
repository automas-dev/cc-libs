local stack = {}

--- Create a new empty stack
function stack:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Push a single element to the top of the stack
function stack:push(e)
    self[#self + 1] = e
end

--- Remove and return a single element from the top of the stack
function stack:pop()
    if #self > 0 then
        return table.remove(self, #self)
    end
end

--- Return the top element of the stack or nil if the stack is empty
function stack:peek()
    if #self > 0 then
        return self[#self]
    end
end

return stack
