local logging = require 'cc-libs.util.logging'
local log = logging.get_logger('planner')

---Check if another point is inline with one of this points axis (ie. 2 axes match)
---@param a Vec3|Point
---@param b Vec3|Point
---@return boolean
local function inline(a, b)
    if a.x ~= b.x then
        return a.y == b.y and a.z == b.z
    elseif a.y ~= b.y then
        return a.x == b.x and a.z == b.z
    elseif a.z ~= b.z then
        return a.x == b.x and a.y == b.y
    else
        return true
    end
end

--[[
Planning

I need a way to define a plan or path
- Moving in a direction
- Mining in a direction (mine up, mine down, mine forward without moving forward)
- Navigate between points
- Choose when to perform a behavior

Is this a state machine?
Are these called routines or subroutines?

This should enable
- Validation of the plan
  - poi / waypoints are defined at the correct time
  - mining paths are inline
  - map can find paths between points at the correct time
- Fuel calculation
- Time calculation

]]

---@enum StepAction
local StepAction = {
    MOVE_TO = 'move_to',
    MINE_TO = 'mine_to',
    NAV_TO = 'nav_to',
    MARK_POI = 'mark_poi',
}

---@class PlanStep
---@field action StepAction

---@class Planner
---@field curr Vec3|Point
---@field nav Nav
---@field map Map
---@field plan table[]
---@field frame LocalFrame?
---@field poi_defined { [string]: true } points of interest defined by mark_poi, used as check in navigate_to_poi
local Planner = {}

---Create a new Planner object
---@param start Vec3|Point
---@param nav Nav
---@param frame? LocalFrame
---@return Planner
function Planner:new(start, nav, frame)
    local o = {
        curr_loc = start,
        nav = nav,
        map = nav.map:copy(),
        plan = {},
        frame = frame,
        poi_defined = {},
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

---Move to a location
---@param point Point
---@param dig_enabled? boolean
function Planner:move_to_point(point, dig_enabled)
    assert(inline(self.curr, point))
    table.insert(self.plan, {
        action = StepAction.MOVE_TO,
        point = point,
        dig_enabled = dig_enabled,
    })
    self.curr = point
end

---Move to a location
---@param point Point
---@param dig_enabled? boolean
function Planner:move_to_poi(point, dig_enabled)
    table.insert(self.plan, {
        action = StepAction.MOVE_TO,
        point = point,
        dig_enabled = dig_enabled,
    })
end

---Move to a location while mining
---@param point Point
---@param dig_up? boolean defaults to false
---@param dig_down? boolean defaults to false
function Planner:mine_to(point, dig_up, dig_down)
    table.insert(self.plan, {
        action = StepAction.MINE_TO,
        point = point,
        dig_up = dig_up,
        dig_down = dig_down,
    })
end

---Navigate to a point of interest from navigation
---@param name string
function Planner:navigate_to_poi(name)
    -- First make sure all poi predefined in nav exist in self.poi_defined
    for poi in pairs(self.nav.poi) do
        self.poi_defined[poi] = true
    end
    assert(self.poi_defined[name], 'poi must be defined first')
    -- TODO can we check if there is a path to name?
    table.insert(self.plan, {
        action = StepAction.NAV_TO,
        poi = name,
    })
end

---Mark the current location as a point of interest
---@param name string
function Planner:mark_poi(name)
    table.insert(self.plan, {
        action = StepAction.MARK_POI,
        name = name,
    })
    self.poi_defined[name] = true
end

---Compile the plan
function Planner:compile() end

---Execute the plan
function Planner:exec() end

return {
    Planner = Planner,
}
