require 'mock'

local patches = {}

---Split a string separated by . into a list of strings
---@param target string
---@return string[] target components
local function separate_parts(target)
    local parts = {}
    for part in target:gmatch('([^\\.]+)') do
        table.insert(parts, part)
    end
    return parts
end

---Patch a global object with MagicMock
---@param target string
function patch(target)
    local parts = separate_parts(target)
    assert(#parts > 0, 'No parts found in target ' .. tostring(target))
    local field = table.remove(parts, #parts)
    local obj = _G
    for _, p in ipairs(parts) do
        obj = obj[p]
    end
    return patch_local(obj, field)
end

---Patch an field with MagicMock
---@param obj table any object with a field to replace with MagicMock
---@param field string name of the field to replace
function patch_local(obj, field)
    local old = obj[field]
    local mock = MagicMock()
    obj[field] = mock
    table.insert(patches, {
        old = old,
        obj = obj,
        field = field,
        mock = mock,
    })
    return mock
end

function reset_patches()
    for _, p in ipairs(patches) do
        p.obj[p.field] = p.old
    end
    patches = {}
end
