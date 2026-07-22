local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('turtle.script.context')

local lexer = require 'cc-libs.turtle.script.parser'
local TSParser = lexer.TSParser
local TSTokenType = lexer.TSTokenType

---@alias TSFunction fun(motion: Motion, count: number, arg: string?): boolean?, string?

---@class TSContext
---@field motion Motion
---@field nav Nav
---@field parser TSParser
---@field native { [string]: TSFunction }
---@field defs { [string]: TSToken[] }
---@field call_stack string[]
---@field vars { [string] : number }
local TSContext = {}

---Create a new TSContext object
---@param motion Motion
---@param nav Nav
---@return TSContext
function TSContext:new(motion, nav)
    local parser = TSParser:new()
    motion.log_fails = false
    local o = {
        motion = motion,
        nav = nav,
        parser = parser,
        native = {},
        defs = {},
        call_stack = {},
        vars = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function TSContext:register_std()
    self:register_print()
    self:register_logic()
    self:register_math()
end

function TSContext:register_print()
    self:register('print', true, function(_, _, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        print(self.vars[arg])
    end)
end

function TSContext:register_logic()
    self:register('test', true, function(_, _, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        return self.vars[arg] and self.vars[arg] ~= 0
    end)
end

function TSContext:register_math()
    self:register('clear', true, function(_, _, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        self.vars[arg] = 0
        return true
    end)
    self:register('inc', true, function(_, count, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        self.vars[arg] = (self.vars[arg] or 0) + count
        return true
    end)
    self:register('dec', true, function(_, count, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        self.vars[arg] = (self.vars[arg] or 0) - count
        return true
    end)
    self:register('mul', true, function(_, count, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        self.vars[arg] = (self.vars[arg] or 0) * count
        return true
    end)
    self:register('div', true, function(_, count, arg)
        -- Should not be possible because of the parser, here for testing
        assert(arg ~= nil and #arg >= 1)
        self.vars[arg] = (self.vars[arg] or 0) / count
        return true
    end)
    -- Math functions with a single argument and single return
    for _, math_name in ipairs({
        'abs',
        'asin',
        'atan',
        'ceil',
        'cos',
        'cosh',
        'deg',
        'exp',
        'floor',
        'rad',
        'sin',
        'sinh',
        'sqrt',
        'tan',
        'tanh',
    }) do
        self:register(math_name, true, function(_, _, arg)
            -- Should not be possible because of the parser, here for testing
            assert(arg ~= nil and #arg >= 1)
            self.vars[arg] = math[math_name](self.vars[arg] or 0)
            return true
        end)
    end
    -- Math functions with two arguments and single return
    for _, math_name in ipairs({ 'atan2', 'max', 'min', 'pow' }) do
        self:register(math_name, true, function(_, count, arg)
            -- Should not be possible because of the parser, here for testing
            assert(arg ~= nil and #arg >= 1)
            self.vars[arg] = math[math_name](self.vars[arg] or 0, count)
            return true
        end)
    end
end

function TSContext:register_turtle()
    self:register_math()
    self:register('f', false, self.motion.forward)
    self:register('b', false, self.motion.backward)
    self:register('l', false, self.motion.left)
    self:register('r', false, self.motion.right)
    self:register('u', false, self.motion.up)
    self:register('d', false, self.motion.down)
    self:register('enable', false, self.motion.enable_dig)
    self:register('disable', false, self.motion.disable_dig)
    self:register('detect', false, turtle.detect)
    self:register('detect_up', false, turtle.detectUp)
    self:register('detect_down', false, turtle.detectUp)
    self:register('m', true, function(_, _, poi_name)
        -- Should not be possible because of the parser, here for testing
        assert(poi_name ~= nil and #poi_name >= 1)
        return pcall(self.nav.mark_poi, self.nav, poi_name)
    end)
    self:register('g', true, function(_, _, poi_name)
        -- Should not be possible because of the parser, here for testing
        assert(poi_name ~= nil and #poi_name >= 1)
        if self.nav:get_poi(poi_name) == nil then
            log:warning('poi', poi_name, 'is missing')
            if self.nav.map:get_waypoint(poi_name) == nil then
                error('Missing poi ' .. tostring(poi_name))
            end
            self.nav:poi_from_waypoint(poi_name)
            log:info('Got poi from waypoint', poi_name)
        end
        local success, path = pcall(self.nav.find_path, self.nav, poi_name)
        if not success then
            log:error('Failed to find path to poi', poi_name)
            return false
        elseif #path < 2 then
            log:error('Path is empty to poi', poi_name)
            return false
        end
        self.nav:follow_path(path)
        return true
    end)
end

---Register a function for name
---@param name string
---@param fn TSFunction
function TSContext:register(name, takes_arg, fn)
    log:debug('Registering native function', name, takes_arg)
    self.native[name] = fn
    if takes_arg then
        log:trace('native function', name, 'takes an argument')
        self.parser:takes_arg(name)
    end
end

---Evaluate a single node in the ast
---@param node TSToken
---@return boolean success
---@return string? error
function TSContext:eval(node)
    -- TODO trace
    log:trace('eval', node)
    -- Define a Function
    if node.type == TSTokenType.DEF then
        assert(node.children ~= nil, 'def has no children')
        log:debug('Defining function', node.name, 'with', #node.children, 'children')
        assert(self.native[node.name] == nil, 'redefining native function ' .. tostring(node.name))
        self.defs[node.name] = node.children
    -- Function Call
    elseif node.type == TSTokenType.CALL then
        local fn_name = node.name
        -- Native Function
        local fn = self.native[fn_name]
        if fn ~= nil then
            log:debug('Evaluating native call', fn_name, node.count, node.arg)

            table.insert(self.call_stack, fn_name)
            local stack_count = #self.call_stack
            log:trace('call stack before is', self.call_stack)

            local count = node.count

            local success, err
            if count == '!' then
                success = true
                while success do
                    success, err = fn(self.motion, 1, node.arg)
                end
            elseif count == '?' then
                fn(self.motion, 1, node.arg)
                success = true
            elseif type(count) == 'string' and count:sub(1, 1) == '#' then
                assert(#count > 1, 'empty var name')
                local var_name = count:sub(2)
                success = true
                local i = 0
                while success do
                    success = fn(self.motion, 1, node.arg)
                    if success then
                        i = i + 1
                    end
                end
                self.vars[var_name] = i
                log:info('Setting var', var_name, 'to', i)
                success = true
            else
                if type(count) == 'string' and count:sub(1, 1) == '$' then
                    assert(#count > 1, 'empty var name')
                    local var_name = count:sub(2)
                    count = self.vars[var_name]
                    if count == nil then
                        return false, 'unknown variable ' .. tostring(var_name)
                    end
                end
                ---@diagnostic disable-next-line: param-type-mismatch
                success, err = fn(self.motion, count, node.arg)
            end

            log:trace('call stack after is', self.call_stack)
            assert(#self.call_stack == stack_count, 'Unbalanced call')
            table.remove(self.call_stack)

            log:debug('Result of call', fn_name, 'is', success, err)
            -- Handle nil as success
            if success == false then
                local msg = 'native function failed ' .. tostring(fn_name)
                if err then
                    msg = msg .. ' : ' .. tostring(err)
                end
                return false, msg
            end
            return true
        end
        -- Defined Function
        local def = self.defs[fn_name]
        if def ~= nil then
            log:debug('Evaluating call', fn_name, node.count)

            table.insert(self.call_stack, fn_name)
            log:trace('call stack before is', self.call_stack)
            local stack_count = #self.call_stack

            local count = node.count

            local success = false
            local err = nil

            if count == '!' then
                -- Loop function count times
                success = true
                while success do
                    for _, child in ipairs(def) do
                        log:trace('Loop', _, 'for function', fn_name)
                        success, err = self:eval(child)
                        -- Stop if any call fails
                        if not success then
                            break
                        end
                    end
                end
            elseif count == '?' then
                for _, child in ipairs(def) do
                    log:trace('Loop', _, 'for function', fn_name)
                    success, err = self:eval(child)
                    -- Stop if any call fails
                    if not success then
                        break
                    end
                end
                success = true
            elseif type(node.count) == 'string' and count:sub(1, 1) == '#' then
                local var_name = count:sub(2)
                local i = 0
                success = true
                while success do
                    for _, child in ipairs(def) do
                        log:trace('Loop', _, 'for function', fn_name)
                        success = self:eval(child)
                        -- Stop if any call fails
                        if not success then
                            break
                        end
                    end
                    if success then
                        i = i + 1
                    end
                end
                self.vars[var_name] = i
                log:info('Setting var', var_name, 'to', i)
                success = true
            else
                if type(node.count) == 'string' and count:sub(1, 1) == '$' then
                    local var_name = count:sub(2)
                    count = self.vars[var_name]
                    if count == nil then
                        return false, 'unknown variable ' .. tostring(var_name)
                    end
                end
                -- Loop function count times
                for _ = 1, count do
                    for _, child in ipairs(def) do
                        log:trace('Loop', _, 'for function', fn_name)
                        success, err = self:eval(child)
                        -- Stop if any call fails
                        if not success then
                            break
                        end
                    end
                end
            end
            log:trace('call stack after is', self.call_stack)

            assert(#self.call_stack == stack_count, 'Unbalanced call')
            table.remove(self.call_stack)

            log:debug('Result of call', fn_name, 'is', success, err)
            -- Handle nil as success
            if success == false then
                return false, 'function failed ' .. tostring(fn_name)
            end
            return true
        end
        return false, 'function not defined ' .. tostring(fn_name)
    -- Execute multiple nodes count times
    elseif node.type == TSTokenType.BLOCK then
        assert(node.children ~= nil)
        log:debug('Evaluating block')
        local count = node.count
        if count == '!' then
            local success = true
            -- Loop count times
            while success do
                -- Run each node in block
                for _, child in ipairs(node.children) do
                    success = self:eval(child)
                    -- Return error if a call fails
                    if not success then
                        break
                    end
                end
            end
        elseif count == '?' then
            -- Run each node in block
            for _, child in ipairs(node.children) do
                local success, err = self:eval(child)
                -- Return error if a call fails
                if not success then
                    break
                end
            end
            success = true
        elseif type(node.count) == 'string' and count:sub(1, 1) == '#' then
            local var_name = count:sub(2)
            local i = 0
            success = true
            while success do
                -- Run each node in block
                for _, child in ipairs(node.children) do
                    success = self:eval(child)
                    -- Return error if a call fails
                    if not success then
                        break
                    end
                end
                if success then
                    i = i + 1
                end
            end
            self.vars[var_name] = i
            log:info('Setting var', var_name, 'to', i)
            success = true
        else
            if type(node.count) == 'string' and count:sub(1, 1) == '$' then
                local var_name = count:sub(2)
                count = self.vars[var_name]
                if count == nil then
                    return false, 'unknown variable ' .. tostring(var_name)
                end
            end
            -- Loop count times
            for _ = 1, node.count do
                -- Run each node in block
                for _, child in ipairs(node.children) do
                    local success, err = self:eval(child)
                    -- Return error if a call fails
                    if not success then
                        return false, err
                    end
                end
            end
        end
        return true
    else
        error('Unknown node type ' .. tostring(node.type))
    end
    return true
end

---Execute a command string
---@param text string
---@return boolean success
---@return string? error
function TSContext:exec(text)
    local ast = self.parser:parse(text)
    for _, node in ipairs(ast) do
        local success, err = self:eval(node)
        if not success then
            return false, err
        end
    end
    return true
end

return {
    TSContext = TSContext,
}
