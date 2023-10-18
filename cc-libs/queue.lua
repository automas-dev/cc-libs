local queue = {}

--- Create a new empty queue
function queue:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--- Push a single element to the back of the queue
function queue:push(e)
    self[#self + 1] = e
end

--- Remove and return a single element from the front of the queue
function queue:pop()
    if #self > 0 then
        return table.remove(self, 1)
    end
end

return queue
