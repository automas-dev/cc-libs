---@meta ccl_stack

---@class stack
local stack = {}

---Create a new empty stack
---@return stack
function stack:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

---Push a single element to the top of the stack
---@param e any element
function stack:push(e)
    self[#self + 1] = e
end

---Remove and return a single element from the top of the stack
---@return any
function stack:pop()
    if #self > 0 then
        return table.remove(self, #self)
    else
        return nil
    end
end

---Return the top element of the stack or nil if the stack is empty
---@return any
function stack:peek()
    if #self > 0 then
        return self[#self]
    else
        return nil
    end
end

return stack
