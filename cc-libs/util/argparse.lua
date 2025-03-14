---@class Arg
---@field name string
---@field help? string
---@field default? any
---@field required boolean
---@field is_multi boolean

---@class Option
---@field short? string
---@field name string
---@field help? string
---@field has_value boolean

---@class ArgParse
---@field name string program name
---@field help? string description of the program
---@field args Arg[] list of positional arguments
---@field args_required number minimum number of positional arguments
---@field options Option[] list of optional arguments / flags
local ArgParse = {}

-- TODO logging

---Create a new ArgParse instance
---@param name string the application name
---@param help? string description of the program
---@return ArgParse
function ArgParse:new(name, help)
    local o = {
        name = name,
        help = help,
        args = {},
        args_required = 0,
        options = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---@class ArgOptions
---@field help? string
---@field default? any
---@field required? boolean
---@field is_multi? boolean

---Add a positional argument
---@param name string argument name
---@param options? ArgOptions additional parameters for the argument
function ArgParse:add_arg(name, options)
    options = options or {}

    for _, a in pairs(self.args) do
        if a.name == name then
            error('Argument ' .. name .. ' already exists')
        end
    end

    for _, o in pairs(self.options) do
        if o.name == name then
            error('Argument ' .. name .. ' has the same name as option ' .. o.name)
        end
    end

    if options.required == nil then
        options.required = true
    end

    if options.default ~= nil then
        options.required = false
    end

    if #self.args > 0 then
        if self.args[#self.args].is_multi then
            error('Argument ' .. name .. ' cannot be evaluated after is_multi arg ' .. self.args[#self.args].name)
        elseif options.default == nil and self.args[#self.args].default ~= nil then
            error('Argument ' .. name .. ' cannot be evaluated after default arg ' .. self.args[#self.args].name)
        elseif options.required and not self.args[#self.args].required then
            error('Argument ' .. name .. ' cannot be evaluated after optional arg ' .. self.args[#self.args].name)
        end
    end

    if options.required then
        self.args_required = self.args_required + 1
    end

    table.insert(self.args, {
        name = name,
        help = options.help,
        default = options.default,
        required = options.required,
        is_multi = options.is_multi or false,
    })
end

---Add an optional argument / flag.
---@param short? string short / single character option
---@param name string long name of the option
---@param help? string help message
---@param has_value? boolean expect a value after this flag
function ArgParse:add_option(short, name, help, has_value)
    assert(short == nil or short:sub(1, 1) ~= '-', 'Short cannot include -')
    assert(name:sub(1, 1) ~= '-', 'Name cannot include -')

    for _, o in pairs(self.options) do
        if o.name == name then
            error('Option ' .. name .. ' already exists')
        end
    end

    for _, a in pairs(self.args) do
        if a.name == name then
            error('Option ' .. name .. ' has the same name as arg ' .. a.name)
        end
    end

    local option = {
        short = short,
        name = name,
        help = help,
        has_value = has_value or false,
    }
    table.insert(self.options, option)
end

---Print the help message
function ArgParse:print_help()
    local message = 'Usage: ' .. self.name
    if #self.options > 0 then
        message = message .. ' [options]'
    end

    for _, arg in ipairs(self.args) do
        if not arg.required then
            message = message .. ' [' .. arg.name
            if arg.default ~= nil then
                message = message .. '|' .. tostring(arg.default)
            end
            message = message .. ']'
        else
            message = message .. ' <' .. arg.name .. '>'
        end
    end

    message = message .. '\n'

    if self.help then
        message = message .. self.help .. '\n'
    end

    if #self.args > 0 then
        message = message .. 'Args:\n'

        for _, arg in ipairs(self.args) do
            message = message .. '    '
            message = message .. arg.name .. ':'
            if arg.help then
                message = message .. ' ' .. arg.help
            end
            message = message .. '\n'
        end
    end

    if #self.options > 0 then
        message = message .. 'Options:\n'

        for _, opt in ipairs(self.options) do
            message = message .. '    '
            if opt.short then
                message = message .. '-' .. opt.short .. '/'
            end
            message = message .. '--' .. opt.name
            if opt.has_value then
                message = message .. ' ' .. opt.name
            end
            message = message .. ':'
            if opt.help then
                message = message .. ' ' .. opt.help
            end
            message = message .. '\n'
        end
    end

    local _, height = term.getCursorPos()
    textutils.pagedPrint(message, height - 2)
end

---Check if an argument is a flag
---@param arg string
---@return string? flag name of this option / flag or nil if it is not
---@return boolean is_short is this a short flag (ie. one char)
local function is_flag(arg)
    if arg:sub(1, 2) == '--' then
        return arg:sub(3), false
    elseif arg:sub(1, 1) == '-' then
        assert(#arg == 2, 'short flag must be a single character')
        return arg:sub(2, 2), true
    else
        return nil, false
    end
end

---Parse arguments and return their values.
---@param args string[] array of arguments to parse
---@return table
function ArgParse:parse_args(args)
    local result = {}

    -- Default options without values to false
    for _, opt in ipairs(self.options) do
        if not opt.has_value then
            result[opt.name] = false
        end
    end

    -- Default value for positional arguments
    for _, arg in ipairs(self.args) do
        if arg.default ~= nil then
            result[arg.name] = arg.default
        end
    end

    local arg_i = 1
    local i = 1
    -- using while instead of for to double increment when option has value
    while i <= #args do
        local v = args[i]
        local flag, is_short = is_flag(v)

        -- option / flag
        if flag then
            if flag == 'h' or flag == 'help' then
                self:print_help()
                os.exit(0)
            end
            local found_flag = false
            for _, opt in ipairs(self.options) do
                if (is_short and flag == opt.short) or (not is_short and flag == opt.name) then
                    if opt.has_value then
                        if i == #args then
                            error('Missing value for option ' .. v)
                        end
                        i = i + 1
                        v = args[i]
                        result[opt.name] = v
                    else
                        result[opt.name] = true
                    end
                    found_flag = true
                    break
                end
            end
            if not found_flag then
                error('Unexpected option ' .. v)
            end

        -- argument
        else
            if arg_i > #self.args then
                if #self.args > 0 and self.args[#self.args].is_multi then
                    table.insert(result[self.args[#self.args].name], v)
                else
                    local sample = tostring(v)
                    if #sample > 30 then
                        sample = sample:sub(1, 30) .. '...'
                    end
                    error('Unexpected value ' .. sample)
                end
            else
                if self.args[arg_i].is_multi then
                    result[self.args[arg_i].name] = { v }
                else
                    result[self.args[arg_i].name] = v
                end
                arg_i = arg_i + 1
            end
        end

        i = i + 1
    end

    if arg_i <= self.args_required then
        local missing = ''
        for j, arg in ipairs(self.args) do
            if j >= arg_i then
                if arg.default ~= nil then
                    break
                end
                missing = missing .. ' ' .. arg.name
            end
        end
        error('Missing required positional arguments' .. missing)
    end

    return result
end

return {
    ArgParse = ArgParse,
}
