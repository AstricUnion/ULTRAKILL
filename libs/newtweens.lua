---@name Tweens
---@author AstricUnion
---@server


---@enum PROPERTY
PROPERTY = {
    NONE = {
        function() end,
        function() end
    },
    POS = {
        function(x) return x:getPos() end,
        function(x, set) x:setPos(set) end
    },
    ANGLES = {
        function(x) return x:getAngles() end,
        function(x, set) x:setAngles(set) end
    },
    LOCALPOS = {
        function(x) return x:getLocalPos() end,
        function(x, set) x:setLocalPos(set) end
    },
    LOCALANGLES = {
        function(x) return x:getLocalAngles() end,
        function(x, set) x:setLocalAngles(set) end
    },
    COLOR = {
        function(x) return x:getColor() end,
        function(x, set) x:setColor(set) end
    },
    SCALE = {
        function(x) return x:getScale() end,
        function(x, set) x:setScale(set) end
    },
    ANGULARVELOCITY = {
        function(x) return x:getAngleVelocity() end,
        function(x, set) x:setAngleVelocity(set) end
    },
    -- Only with holograms!
    LOCALANGULARVELOCITY = {
        function(x) return x.angular end,
        function(x, set)
            if !x.angular then x.angular = Vector() end
            x:setLocalAngularVelocity(set)
            x.angular = set
        end
    },
    VELOCITY = {
        function(x) return x:getVelocity() end,
        function(x, set) x:setVelocity(set) end
    },
    ADDVELOCITY = {
        function(x) return x:getVelocity() end,
        function(x, set) x:addVelocity(set) end
    }
}


---[SHARED] Parameter class, to store data about tweening element
---@class Param
---@field ent Entity Entity to perform tweening
---@field startAt number Second to start parameter tweening from
---@field endAt number Second to end parameter tweening
---@field duration number Tweening duration
---@field property PROPERTY Property to tween
---@field from any Property from
---@field to any | fun() Goal to tween
---@field easing? fun(x: number): number Function, that gets 0 to 1 on input and gives eased value. Nil to linear
---@field process? fun(self: Tween, eased: number) Process callback (on every Think)
---@field onEnd? fun(self: Tween) Callback on parameter ending
local Param = {}
Param.__index = Param
Param.__call = Param.new


local function linear(x) return x end


---[SHARED] Create new parameter
---@param ent Entity Entity to perform tweening
---@param startAt number Second to start parameter tweening from
---@param endAt number Second to end parameter tweening
---@param property PROPERTY Property to tween
---@param to any | fun() Goal to tween
---@param easing? fun(x: number): number Function, that gets 0 to 1 on input and gives eased value. Nil to linear
---@param process? fun(self: Tween, eased: number) Process callback (on every Think)
---@param onEnd? fun(self: Tween) Callback on parameter ending
function Param:new(ent, startAt, endAt, property, to, easing, process, onEnd)
    return setmetatable(
        {
            ent = ent,
            startAt = startAt,
            endAt = endAt,
            duration = endAt - startAt,
            property = property,
            from = property[1](ent),
            to = to,
            easing = easing or linear,
            process = process,
            onEnd = onEnd
        },
        Param
    )
end


---[SHARED] Update a parameter with a process value
---@param process number
function Param:update(process)
    process = process - self.startAt
    local duration = self.duration
    if process >= duration then return end
    if process < 0 then return end
    local startValue = self.from
    local toVal = self.to
    local endValue = isfunction(toVal) and toVal() or toVal
    local change = endValue - startValue
    if self.endAt == 3  then
        print(process, duration)
    end
    local eased = startValue + change * self.easing(process / duration)
    self.property[2](self.ent, eased)
end


---[SHARED] Class to tween parameters
---@class Tween
---@field params table
---@field process number Process of the tween (in seconds)
local Tween = {}
Tween.__index = Tween
Tween.__call = Tween.new


function Tween:new(...)
    return setmetatable(
        {
            params = {...},
            process = 0
        },
        Tween
    )
end


function Tween:update()
    local process = self.process
    process = process + game.getTickInterval()
    for _, v in ipairs(self.params) do
        v:update(process)
    end
    self.process = process
end


local startPos = chip():getPos() + Vector(0, 0, 10)
local holo = hologram.create(startPos, Angle(), "models/holograms/cube.mdl")
if !holo then return end

local tw = Tween:new(
    Param:new(holo, 1, 5, PROPERTY.ANGLES, Angle(53, 98, 62), math.easeInOutCubic),
    Param:new(holo, 1, 3, PROPERTY.POS, startPos + Vector(0, 50, 0), math.easeInOutBack)
)

hook.add("Think", "", function()
    tw:update()
end)

