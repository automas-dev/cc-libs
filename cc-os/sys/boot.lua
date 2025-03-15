---@diagnostic disable: undefined-field
package.path = '../?.lua;../?/init.lua;/cc-libs/?.lua;/cc-libs/?/init.lua;' .. package.path

local paths = '?.lua;?/init.lua;'
paths = paths .. '/?.lua;/?/init.lua;'
paths = paths .. '/sys/modules/?.lua;/sys/modules/?/init.lua'
paths = paths .. '/rom/modules/main/?;/rom/modules/main/?.lua;/rom/modules/main/?/init.lua;'
if _G.turtle then
    paths = paths .. '/rom/modules/turtle/?;/rom/modules/main/?.lua;/rom/modules/turtle/?/init.lua;'
end

local env = setmetatable({}, { __index = _G })
---@diagnostic disable-next-line: missing-fields
env.package = {
    path = paths,
    cpath = '',
    config = '/\n;\n?\n!\n-',
    loaders = _G.loaders,
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
    searchpath = _G.package.searchpath,
}

local kernel = assert(loadfile('sys/kernel.lua', 't', env), 'Failed to load kernel')

local success, err = xpcall(kernel, debug.traceback)

if not success then
    term.setTextColor(colors.red)
    print('Kernel panic')
    term.setTextColor(colors.gray)
    print(err)
    term.setTextColor(colors.white)
end
