local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('profile')

local json = require 'cc-libs.util.json'

---@class ProfilerResult
---@field min number
---@field max number
---@field avg number
---@field sum number
---@field data number[]|nil

---@class Profiler
---@field times { [string] : number[] }
local Profiler = {
    active = 0,
}

---Create a new Profiler object
---@return Profiler
function Profiler:new()
    local o = {
        times = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Dump results to a json file
---@param path string
function Profiler:dump(path)
    -- TODO test
    local file = assert(io.open(path, 'w'))
    file:write(json.encode(self:calc_results()))
    file:close()
end

---Calculate the results of all calls
---@return { [string]: ProfilerResult }
function Profiler:calc_results()
    ---@type { [string]: ProfilerResult }
    local res = {}
    for name, data in pairs(self.times) do
        assert(#data > 0, name .. ' is missing data')

        local min = math.min(table.unpack(data))
        local max = math.max(table.unpack(data))
        local sum = 0
        for _, v in ipairs(data) do
            sum = sum + v
        end
        local avg = sum / #data
        res[name] = {
            min = min,
            max = max,
            avg = avg,
            sum = sum,
            data = data,
        }
    end
    return res
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
    if not self.times[name] then
        self.times[name] = {}
    end
    table.insert(self.times[name], delta)

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
