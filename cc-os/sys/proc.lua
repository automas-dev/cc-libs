---@class Process
---@field pid number
---@field co thread
---@field env table
---@field filter? string
local Process = {}

---@param pid number
---@param f fun()
---@param env table
function Process:new(pid, f, env)
    local o = {
        pid = pid,
        co = coroutine.create(f),
        env = env,
    }
    setmetatable(o, self)
    self.__index = self

    kernel.hook('*', function(e, e_d)
        self:resume(e, e_d)
    end)

    env.os.pullEvent = function(filter)
        return coroutine.yield(filter)
    end

    return o
end

function Process:resume(event, ...)
    if coroutine.status(self.co) == 'dead' then
        return
    end

    if not self.filter or self.filter == event or event == 'terminate' then
        local success, res = coroutine.resume(self.co, event, ...)

        self.filter = res
        return success, res
    end
end

return {
    Process = Process,
}
