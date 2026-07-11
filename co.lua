local function create(...)
    local tFns = table.pack(...)
    local tCos = {}
    for i = 1, tFns.n, 1 do
        local fn = tFns[i]
        if type(fn) ~= 'function' then
            error('bad argument #' .. i .. ' (function expected, got ' .. type(fn) .. ')', 3)
        end

        tCos[i] = coroutine.create(fn)
    end

    return tCos
end

local function runUntilLimit(_routines, _limit)
    local count = #_routines
    if count < 1 then
        return 0
    end
    local living = count

    local tFilters = {}
    local eventData = { n = 0 }
    while true do
        for n = 1, count do
            local r = _routines[n]
            if r then
                if tFilters[r] == nil or tFilters[r] == eventData[1] or eventData[1] == 'terminate' then
                    local ok, param = coroutine.resume(r, table.unpack(eventData, 1, eventData.n))
                    if not ok then
                        error(param, 0)
                    else
                        tFilters[r] = param
                    end
                    if coroutine.status(r) == 'dead' then
                        _routines[n] = nil
                        living = living - 1
                        if living <= _limit then
                            return n
                        end
                    end
                end
            end
        end
        for n = 1, count do
            local r = _routines[n]
            if r and coroutine.status(r) == 'dead' then
                _routines[n] = nil
                living = living - 1
                if living <= _limit then
                    return n
                end
            end
        end
        eventData = table.pack(os.pullEventRaw())
    end
end

function waitForAny(...)
    local routines = create(...)
    return runUntilLimit(routines, #routines - 1)
end

local function forward()
    while true do
        print('f')
        turtle.forward()
        print('b')
        turtle.back()
        print('e')
    end
end

local function read()
    while true do
        local e, n, t = os.pullEvent('custom')
        print('Got custom event with data', n, t)
    end
end

local function write()
    while true do
        sleep(1)
        os.queueEvent('custom', 1, os.epoch())
        sleep(0.2)
        os.queueEvent('custom', 2, os.epoch())
    end
end

local function wait_for_q()
    repeat
        local _, key = os.pullEvent('key')
    until key == keys.q
    print('Q was pressed!')
end

waitForAny(forward, read, write, wait_for_q)
