local paths = '?.lua;?/init.lua;'
paths = paths .. '/?.lua;/?/init.lua;'
paths = paths .. '/sys/modules/?.lua;/sys/modules/?/init.lua'
paths = paths .. '/rom/modules/main/?;/rom/modules/main/?.lua;/rom/modules/main/?/init.lua;'
if _G.turtle then
    paths = paths .. '/rom/modules/turtle/?;/rom/modules/main/?.lua;/rom/modules/turtle/?/init.lua;'
end

local env = setmetatable({}, { __index = _ENV })

local function search_preload(module)
    if env.package.preload[module] ~= nil then
        return env.package.preload[module](module, env)
    end
end

local function search_path(module)
    local module_path = module:gsub('%.', '/')

    for path in env.package.path:gmatch('[^;]+') do
        local filepath = path:gsub('%?', module_path)
        if fs.exists(filepath) and not fs.isDir(filepath) then
            return loadfile(filepath, 't', env)
        end
    end
end

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
        utf8 = _G.utf8,
    },
    loaders = {
        search_preload,
        search_path,
    },
}
env.package.preload.package = env.package

local kernel = assert(loadfile('sys/kernel.lua', 't', env), 'Failed to load kernel')

local success, err = xpcall(kernel, debug.traceback)

if not success then
    term.setTextColor(colors.red)
    print('Kernel panic')
    term.setTextColor(colors.gray)
    print(err)
    term.setTextColor(colors.white)
end
