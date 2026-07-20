local lexer = require 'cc-libs.turtle.script.parser'
local TSParser = lexer.TSParser
local TSTokenType = lexer.TSTokenType

---@alias TSFunction fun(motion: Motion, count: number, arg: string?, nav: Nav): boolean

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
    -- TODO register default functions
    return o
end

function TSContext:register_defaults()
    self:register('f', false, self.motion.forward)
    self:register('b', false, self.motion.backward)
    self:register('l', false, self.motion.left)
    self:register('r', false, self.motion.right)
    self:register('u', false, self.motion.up)
    self:register('d', false, self.motion.down)
    self:register('enable', false, self.motion.enable_dig)
    self:register('disable', false, self.motion.disable_dig)
    self:register('m', true, function(_, _, poi_name, nav)
        assert(arg ~= nil)
        return pcall(nav.mark_poi, nav, poi_name)
    end)
    self:register('g', true, function(_, _, poi_name, nav)
        assert(arg ~= nil)
        if nav:get_poi(poi_name) == nil then
            if nav.map:get_waypoint(poi_name) == nil then
                -- error('Missing poi ' .. tostring(poi_name))
                return false
            end
            nav:poi_from_waypoint(poi_name)
        end
        local success, path = pcall(nav.find_path, nav, poi_name)
        if not success then
            return false
        elseif #path < 2 then
            return false
        end
        nav:follow_path(path)
        return true
    end)
end

---Register a function for name
---@param name string
---@param fn TSFunction
function TSContext:register(name, takes_arg, fn)
    self.native[name] = fn
    if takes_arg then
        self.parser:does_token_take_arg(name)
    end
end

---Evaluate a single node in the ast
---@param node TSToken
---@return boolean success
function TSContext:eval(node)
    if node.type == TSTokenType.DEF then
        assert(node.children ~= nil)
        assert(node.arg ~= nil)
        assert(self.native[node.arg] == nil, 'redefining native function ' .. tostring(node.arg))
        self.defs[node.arg] = node.children
    elseif node.type == TSTokenType.CALL then
        assert(node.arg ~= nil)
        local fn_name = node.arg
        local fn = self.native[fn_name]
        if fn ~= nil then
            table.insert(self.call_stack, fn_name)
            local stack_count = #self.call_stack
            local res = fn(self.motion, node.count, node.arg, self.nav)
            assert(#self.call_stack == stack_count, 'Unbalanced call')
            table.remove(self.call_stack)
            return res
        end
        local def = self.defs[fn_name]
        if def ~= nil then
            table.insert(self.call_stack, fn_name)
            local stack_count = #self.call_stack
            local res = false
            for _, child in ipairs(def) do
                res = self:eval(child)
                if not res then
                    break
                end
            end
            assert(#self.call_stack == stack_count, 'Unbalanced call')
            table.remove(self.call_stack)
            return res
        end
        return false
    elseif node.type == TSTokenType.LOOP then
        assert(node.children ~= nil)
        for _, child in ipairs(node.children) do
            if not self:eval(child) then
                return false
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
function TSContext:exec(text)
    local ast = self.parser:parse(text)
    for _, node in ipairs(ast) do
        if not self:eval(node) then
            return false
        end
    end
    return true
end

return {
    TSContext = TSContext,
}
