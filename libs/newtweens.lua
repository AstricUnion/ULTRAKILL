---@name Tweens
---@author AstricUnion
---@server

---Control class for tweens
---@class tweens
local tweens = {}
tweens.runned = {}


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
---@field process? fun(eased: number) Process callback (on every Think)
---@field onEnd? fun() Callback on parameter ending
local Param = {}
Param.__index = Param
Param.__call = Param.new


local function linear(x) return x end


---[SHARED] Create new parameter
---@param ent Hologram Entity to perform tweening
---@param startAt number Second to start parameter tweening from
---@param endAt number Second to end parameter tweening
---@param property Property Property to tween
---@param from any | fun() | nil Start values to tween. Default gets position on start
---@param to any | fun() Goal for tween
---@param easing? fun(x: number): number Function, that gets 0 to 1 on input and gives eased value. Nil to linear
---@param process? fun(eased: number) Process callback (on every Think)
---@param onEnd? fun() Callback on parameter ending
function Param:new(ent, startAt, endAt, property, from, to, easing, process, onEnd)
    return setmetatable(
        {
            ent = ent,
            startAt = startAt,
            endAt = endAt,
            duration = endAt - startAt,
            property = property,
            from = from or property.get(ent),
            to = to,
            easing = easing or linear,
            process = process,
            onEnd = onEnd
        },
        Param
    )
end


---[INTERNAL] Update a parameter with a process value
---@param process number
function Param:update(process)
    self.from = self.from or self.property.get(self.ent)
    local fromVal = self.from
    local startValue = isfunction(fromVal) and fromVal() or fromVal
    local toVal = self.to
    local endValue = isfunction(toVal) and toVal() or toVal
    local change = endValue - startValue
    local eased = self.easing(process / self.duration)
    local tweened = startValue + change * eased
    self.property.set(self.ent, tweened)
    local proc = self.process
    if proc then
        proc(eased)
    end
end


---[SHARED] Class to tween parameters
---@class Tween
---@field params table<string, TweenElement>
---@field process number Process of the tween (in seconds)
---@field duration number Duration of the tween
---@field paused boolean Is tween paused. Default true
---@field isFinished boolean Is tween already finished 
local Tween = {}
Tween.__index = Tween
Tween.__call = Tween.new


---[SHARED] Create new tween
---@param ... TweenElement
---@return Tween
function Tween:new(...)
    local params = {...}
    local duration = 0
    for _, v in ipairs(params) do
        local endAt = v.endAt
        if endAt <= duration then goto cont end
        duration = endAt
        ::cont::
    end
    local obj = setmetatable(
        {
            params = params,
            duration = duration,
            process = 0,
            paused = true,
            isFinished = false
        },
        Tween
    )
    tweens.runned[#tweens.runned+1] = obj
    return obj
end


function Tween:update()
    if self.paused then return end
    local process = self.process
    if process >= self.duration then
        self.paused = true
        self.isFinished = true
        return
    end
    for _, v in ipairs(self.params) do
        local relativeProcess = process - v.startAt
        if relativeProcess < 0 then goto cont end
        local duration = v.duration
        if relativeProcess >= duration then goto cont end
        v:update(relativeProcess)
        ::cont::
    end
    process = process + game.getTickInterval()
    self.process = process
end


---[SHARED] Start tween
function Tween:start()
    if self.isFinished then return end
    self.paused = false
    self:update()
end


---[SHARED] Reset tween process 
function Tween:reset()
    self.process = 0
    self.isFinished = false
    self:update()
end


---[SHARED] Pause tween
function Tween:stop()
    self.paused = true
end


---[SHARED] Remove tween
function Tween:remove()
    table.removeByValue(tweens.runned, self)
    setmetatable(self, nil)
end


hook.add("Think", "AUTweenThink", function()
    for _, tw in ipairs(tweens.runned) do
        tw:update()
    end
end)


---Create new tween with elements
---@param ... TweenElement
---@return Tween
function tweens.new(...)
    return Tween:new(...)
end

tweens.Param = Param
tweens.TweenElement = TweenElement
tweens.PROPERTY = PROPERTY

return tweens
