local function forward()
    while true do
        -- print('f')
        turtle.forward()
        -- print('b')
        turtle.back()
        -- print('e')
    end
end

local function square()
    while true do
        for _ = 1, 4 do
            for _ = 1, 4 do
                turtle.forward()
            end
            turtle.turnRight()
        end
        sleep(2)
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

local co = coroutine.create(square)

-- local i = 300

local tFilters = nil
local eventData = { n = 0 }
while coroutine.status(co) ~= 'dead' do
    if tFilters == nil or tFilters == eventData[1] or eventData[1] == 'terminate' then
        local ok, param = coroutine.resume(co, table.unpack(eventData, 1, eventData.n))
        -- print('Param is', param)
        if not ok then
            error(param, 0)
        else
            tFilters = param
        end
    end
    eventData = table.pack(os.pullEventRaw())
    -- eventData = { 'turtle_response', i, true, n = 3 }
    -- i = i + 1
    print(textutils.serialize(eventData, { compact = true }))
end
