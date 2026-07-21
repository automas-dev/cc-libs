local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('turtle.script.context')

local lexer = require 'cc-libs.turtle.script.parser'
local TSParser = lexer.TSParser
local TSTokenType = lexer.TSTokenType

---@alias TSFunction fun(motion: Motion, count: number, arg: string?): boolean, string?

---@class TSContext
---@field motion Motion
---@field nav Nav
---@field parser TSParser
---@field native { [string]: TSFunction }
---@field defs { [string]: TSToken[] }
---@field call_stack string[]
local TSContext = {}

---Create a new TSContext object
---@param motion Motion
---@param nav Nav
---@return TSContext
function TSContext:new(motion, nav)
    local parser = TSParser:new()
    local o = {
        motion = motion,
        nav = nav,
        parser = parser,
        native = {},
        defs = {},
        call_stack = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
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

            local success, err
            if node.count == '!' then
                while fn(self.motion, 1, node.arg) do
                end
            else
                ---@diagnostic disable-next-line: param-type-mismatch
                success, err = fn(self.motion, node.count, node.arg)
            end

            log:trace('call stack after is', self.call_stack)
            assert(#self.call_stack == stack_count, 'Unbalanced call')
            table.remove(self.call_stack)

            log:debug('Result of call', fn_name, 'is', success, err)
            -- Handle nil as success
            if success == false then
                return false, 'native function failed ' .. tostring(fn_name)
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
            else
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
                -- Run each node in loop
                for _, child in ipairs(node.children) do
                    success = self:eval(child)
                    -- Return error if a call fails
                    if not success then
                        break
                    end
                end
            end
        else
            -- Loop count times
            for _ = 1, node.count do
                -- Run each node in loop
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
