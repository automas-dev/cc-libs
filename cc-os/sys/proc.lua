local kernel = _G.kernel

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
        time = 0,
        hooks = {},
    }
    setmetatable(o, self)
    self.__index = self

    kernel.hook('*', o.pid, function(e, e_d)
        self.resume(o, e, e_d)
    end)

    env.os.pullEvent = function(filter)
        return coroutine.yield(filter)
    end

    return o
end

function Process:alive()
    return coroutine.status(self.co) ~= 'dead'
end

function Process:resume(event, ...)
    if not self:alive() then
        error('Process ' .. self.pid .. ' is already dead')
        return false
    end

    if not self.filter or self.filter == event or event == 'terminate' then
        local start_time = os.clock()
        local success, res = coroutine.resume(self.co, event, ...)
        local end_time = os.clock()

        self.time = self.time + (end_time - start_time)
        self.filter = res
        return success, res
    end
end

return {
    Process = Process,
}
