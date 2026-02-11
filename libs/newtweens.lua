---@name Tweens
---@author AstricUnion
---@server

---@alias propGet fun(ent: Hologram): any
---@alias propSet fun(ent: Hologram, value: any)

---@class Property
---@field get propGet
---@field set propSet
local Property = {}
Property.__index = Property

---@param get propGet
---@param set propSet
function Property:new(get, set)
    return setmetatable(
        {
            get = get,
            set = set
        },
        Property
    )
end


---@enum PROPERTY
local PROPERTY = {
    NONE = Property:new(
        function() end,
        function() end
    ),
    POS = Property:new(
        function(x) return x:getPos() end,
        function(x, set) x:setPos(set) end
    ),
    ANGLES = Property:new(
        function(x) return x:getAngles() end,
        function(x, set) x:setAngles(set) end
    ),
    LOCALPOS = Property:new(
        function(x) return x:getLocalPos() end,
        function(x, set) x:setLocalPos(set) end
    ),
    LOCALANGLES = Property:new(
        function(x) return x:getLocalAngles() end,
        function(x, set) x:setLocalAngles(set) end
    ),
    COLOR = Property:new(
        function(x) return x:getColor() end,
        function(x, set) x:setColor(set) end
    ),
    SCALE = Property:new(
        function(x) return x:getScale() end,
        function(x, set) x:setScale(set) end
    ),
    ANGULARVELOCITY = Property:new(
        function(x) return x:getAngleVelocity() end,
        function(x, set) x:setAngleVelocity(set) end
    ),
    -- Only with holograms!
    LOCALANGULARVELOCITY = Property:new(
        function(x) return x.angular end,
        function(x, set)
            if !x.angular then x.angular = Vector() end
            x:setLocalAngularVelocity(set)
            x.angular = set
        end
    ),
    VELOCITY = Property:new(
        function(x) return x:getVelocity() end,
        function(x, set) x:setVelocity(set) end
    ),
    ADDVELOCITY = Property:new(
        function(x) return x:getVelocity() end,
        function(x, set) x:addVelocity(set) end
    )
}


---[SHARED] Base tween element
---@class TweenElement
---@field startAt number Second to start element from
---@field endAt number Second to end element
---@field duration number Element duration (endAt - startAt)
local TweenElement = {}
TweenElement.__index = TweenElement


---[SHARED] Create new base element (this is a empty element to inherit)
---@param startAt number
---@param endAt number
---@return TweenElement
function TweenElement:new(startAt, endAt)
    return setmetatable(
        {
            startAt = startAt,
            endAt = endAt,
            duration = endAt - startAt
        },
        TweenElement
    )
end


---[INTERNAL] Function to update element
---@param process number Relative number to process element, in seconds
function TweenElement:update(process) end


---[SHARED] Parameter class, to store data about tweening element
---@class Param: TweenElement
---@field ent Hologram to perform tweening
---@field property Property Property to tween
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
---@param ent Hologram Entity to perform tweening
---@param startAt number Second to start parameter tweening from
---@param endAt number Second to end parameter tweening
---@param property Property Property to tween
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
            from = property.get(ent),
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
    local startValue = self.from
    local toVal = self.to
    local endValue = isfunction(toVal) and toVal() or toVal
    local change = endValue - startValue
    local eased = startValue + change * self.easing(process / self.duration)
    self.property.set(self.ent, eased)
end


---[SHARED] Class to tween parameters
---@class Tween
---@field params table
---@field process number Process of the tween (in seconds)
local Tween = {}
Tween.__index = Tween
Tween.__call = Tween.new


---[SHARED] Create new tween
---@param ... Param
---@return Tween
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
        process = process - v.startAt
        local duration = v.duration
        if process >= duration then return end
        if process < 0 then return end
        v:update(process)
    end
    self.process = process
end


local startPos = chip():getPos() + Vector(0, 0, 10)
local holo = hologram.create(startPos, Angle(), "models/holograms/cube.mdl")
if !holo then return end

local tw = Tween:new(
    Param:new(holo, 0, 5, PROPERTY.ANGLES, Angle(53, 98, 62), math.easeInOutCubic),
    Param:new(holo, 5, 10, PROPERTY.POS, startPos + Vector(0, 50, 0), math.easeInOutBack)
)

hook.add("Think", "AUTweenThink", function()
    tw:update()
end)

