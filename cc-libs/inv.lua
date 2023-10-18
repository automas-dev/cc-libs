os.loadAPI('util.lua')
os.loadAPI('manifest.lua')
os.loadAPI('log.lua')

log.set_level(log.levels.debug)
log.info('Logging enabled')

local function try_pull()
    local i = 0
    while turtle.suckDown() do
        i = i + 1
    end
    return i
end

local function has_items()
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            return true
        end
    end
    return false
end

local function print_items()
    for i = 1, 16 do
        local n = turtle.getItemCount(i)
        if n > 0 then
            print('Slot '..i..' has '..n..' items')
            local t = turtle.getItemDetail(i)
            for k,v in pairs(t) do
                print('    '..k..' : '..v)
            end
        end
    end
end

local function find_free_slot()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            log.debug('free_slot at '..i)
            return i
        end
    end
    log.debug('No free slots found in turtle inventory')
    return 0
end

manifest.init()
-- print(manifest.get('minecraft:chest'))
-- print(manifest.get('minecraft:diamond', 3))
-- print(manifest.index('minecraft:diamond'))
-- print(manifest.set('minecraft:diamond', 64*2))
-- print(manifest.index('minecraft:diamond'))
-- manifest.save()

local function go_forward(count)
    count = count or 1
    for i = 1, count do
        turtle.forward()
    end
end

local function store_item(slot, name, count)
    log.debug('store_item('..slot..', '..name..', '..count..')')
    
    local mcount = manifest.get(name)
    log.debug('Manifest had '..mcount..' items')

    local has_chest = manifest.set(name, mcount + count)
    log.debug('Manifest had_chest : '..tostring(has_chest))
   
    local index = manifest.index(name)
    log.debug('index is '..index)
    go_forward()
    if not has_chest then
        local free = find_free_slot()
        if free == 0 then return end
        turtle.select(free)
        turtle.suckDown(2)
    end

    log.info('Moving')
    log.debug('forward '..tostring(index * 2 - 2))
    turtle.turnRight()
    go_forward(index * 2 - 2)
    turtle.turnLeft()

    if not has_chest then
        log.debug('Placing first chest')
        turtle.placeDown()
        turtle.turnRight()
        go_forward()
        turtle.turnLeft()

        log.debug('Placing second chest')
        turtle.placeDown()
        turtle.turnLeft()
        go_forward()
        turtle.turnRight()
    end

    turtle.select(slot)
    turtle.dropDown(count)
    log.debug('Dropped '..count..' items from slot '..slot)

    log.info('Returning')
    turtle.turnLeft()
    go_forward(index * 2 - 2)
    turtle.turnRight()
    turtle.back()

    manifest.save()
end

local function store_items()
    for i = 1, 16 do
       local meta = turtle.getItemDetail(i)
       if meta then
           log.debug('store_items(): found '..meta.name..', '..meta.count..' in turtle slot '..i)
           store_item(i, meta.name, meta.count)
       end
   end      
end

while true do
   try_pull()
   if has_items() then
       log.info('Found items, moveing to storage')
       store_items()
       log.info('Done storing items')
   end
   os.sleep(1)
end
