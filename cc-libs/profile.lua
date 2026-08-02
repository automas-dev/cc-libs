local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('profile')

---@class Profiler
---@field results { [string] : number[] }
local Profiler = {
    active = 0,
}

---Create a new Profiler object
---@return Profiler
function Profiler:new()
    local o = {
        results = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Call a function and track its execution time
---@generic T
---@generic R
---@param name string name used to store results
---@param fn fun(T): R function to run and profile
---@param ... T to the function
---@return R ... result of `fn`
function Profiler:wrap_call(name, fn, ...)
    -- Check if this is inside a function that's also calculating execution time
    if Profiler.active > 0 then
        log:warning('Nested profiling will produce inaccurate results, nested', Profiler.active)
    end
    Profiler.active = Profiler.active + 1

    -- Run the function and calculate its time
    local start = os.clock()
    local res = { pcall(fn, ...) }
    local delta = os.clock() - start

    -- Create alias for readability
    local success = res[1]
    log:trace('Trace is', success, 'with delta', delta)

    -- Store the delta time, create the array if needed
    if not self.results[name] then
        self.results[name] = {}
    end
    table.insert(self.results[name], delta)

    -- Handle errors by re-raising
    if not success then
        Profiler.active = Profiler.active - 1
        assert(Profiler.active >= 0, 'Profiler is not tracking executions correctly')
        error(res[2], 0)
    end

    -- Handle success by returning results
    Profiler.active = Profiler.active - 1
    assert(Profiler.active >= 0, 'Profiler is not tracking executions correctly')
    return table.unpack(res, 2)
end

---Return a wrapped function that tracks the execution time of `fn`
---@generic T : function
---@param name string name used to store results
---@param fn T function to run catching, logging and re-raising errors
---@return T wrapped_fn function wrapping `fn`
function Profiler:wrap_fn(name, fn)
    return function(...)
        return self:wrap_call(name, fn, ...)
    end
end

return {
    Profiler = Profiler,
}
