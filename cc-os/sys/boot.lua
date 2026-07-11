---Setup a custom lua environment for the kernel

-- Search paths for lua require
local paths = '?.lua;?/init.lua;'
paths = paths .. '/?.lua;/?/init.lua;'
paths = paths .. '/sys/modules/?.lua;/sys/modules/?/init.lua'
paths = paths .. '/rom/modules/main/?;/rom/modules/main/?.lua;/rom/modules/main/?/init.lua;'
if _G.turtle then
    paths = paths .. '/rom/modules/turtle/?;/rom/modules/main/?.lua;/rom/modules/turtle/?/init.lua;'
end

-- Make new env table
local env = setmetatable({}, { __index = _ENV })

-- Called from require to find packages already loaded before boot.lua was run
local function search_preload(module)
    if env.package.preload[module] ~= nil then
        return env.package.preload[module](module, env)
    end
end

-- Called from require to find packages in search path
local function search_path(module)
    local module_path = module:gsub('%.', '/')

    for path in env.package.path:gmatch('[^;]+') do
        local filepath = path:gsub('%?', module_path)
        if fs.exists(filepath) and not fs.isDir(filepath) then
            return loadfile(filepath, 't', env)
        end
    end
end

-- Custom environment
env.package = {
    path = paths,
    cpath = '',
    config = '/\n;\n?\n!\n-',
    preload = {},
    loaded = {
        _G = _G,
        bit32 = bit32,
        coroutine = coroutine,
        debug = debug,
        io = io,
        math = math,
        os = os,
        string = string,
        table = table,
        ---@diagnostic disable-next-line: undefined-field
        utf8 = _G.utf8,
    },
    loaders = {
        search_preload,
        search_path,
    },
}
-- TODO is this correct / does this work? If so what does it do?
env.package.preload.package = env.package

-- Load kernel from file
local kernel, err = loadfile('sys/kernel.lua', 't', env)
if not kernel then
    term.setTextColor(colors.red)
    print('Failed to load kernel')
    term.setTextColor(colors.gray)
    print(err)
    term.setTextColor(colors.white)
    return
end

-- Execute kernel
local success
success, err = xpcall(kernel, debug.traceback)
if not success then
    term.setTextColor(colors.red)
    print('Kernel panic')
    term.setTextColor(colors.gray)
    print(err)
    term.setTextColor(colors.white)
    return
end
