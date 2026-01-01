---@name ULTRAKILL
---@author AstricUnion
---@shared
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/tweens.lua as tweens
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/sounds.lua as sounds
---@include ultrakill/src/controller.lua
---@include ultrakill/src/model.lua
---@include ultrakill/src/weapons.lua

local CHIPPOS = chip():getPos()
local astrosounds = require("sounds")

-- Constants --
local GRAVITY = 980
local SPEED = 500
local SLIDESPEED = 800
local SLIDEMOVESPEED = 100
local DASHSPEED = 30000
local DASHDURATION = 0.1
local DASHJUMPSPEED = 800
local SLAMSPEED = 2000
local CLINGSPEED = 1960
local JUMP = 700
local CAMERAHEIGHT = {
    DEFAULT = 70,
    SLIDE = 30
}

---@enum STATES
local STATES = {
    Idle = 0,
    Slam = 1,
    Dash = 2,
    DashJump = 3,
    Slide = 4,
    Cling = 5,
    WallJump = 6
}

if SERVER then
    require("tweens")

    ---@class PlayerController
    ---@module 'controller'
    local PlayerController = require("ultrakill/src/controller.lua")

    local sounds = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/main/sounds/"
    hook.add("ClientInitialized", "Sounds", function(ply)
        astrosounds.preload(
            ply,
            Sound:new("jump", 1, false, sounds .. "Jump.mp3"),
            Sound:new("dash", 1, false, sounds .. "Dash.mp3"),
            Sound:new("land", 1, false, sounds .. "Landing.mp3"),
            Sound:new("landHeavy", 1, false, sounds .. "LandingHeavy.mp3"),
            Sound:new("slide", 1, true, sounds .. "Slide.mp3"),
            Sound:new("ricochet", 1, false, sounds .. "Ricochet.mp3")
        )
    end)


    ---Mankind is dead. Blood is fuel. Hell is full.
    ---@class V1
    ---@field controller PlayerController
    ---@field model table<string, Hologram | table>
    ---@field weapons table<string, Hologram | table>
    ---@field animations Animations
    ---@field seat Vehicle
    ---@field state STATES
    ---@field dashRemain number
    ---@field movementVelocity Vector
    ---@field slamHeight? number
    ---@field slideDirection? Vector
    ---@field dashDirection? Vector
    local V1 = {}
    V1.__index = V1

    ---@param pos Vector
    ---@param seat Vehicle
    ---@return V1?
    function V1:new(pos, seat)
        local controller = PlayerController:new(pos, seat, CAMERAHEIGHT.DEFAULT, Vector(20, 20, 75))
        if !controller then return end
        controller.body:setHealth(100)
        ---@module 'ultrakill.src.model'
        local modelInfo = require("ultrakill/src/model.lua")
        local model = modelInfo[1]
        local animations = modelInfo[2]
        model.Main:setPos(pos)
        model.Main:setParent(controller.body)
        animations:play("idle")
        ---@module 'ultrakill.src.weapons'
        local weapons = require("ultrakill/src/weapons.lua")
        weapons.Revolver[1]:setPos(model.RightArm.Palm:getPos() + Vector(1, 0, -2))
        weapons.Revolver[1]:setAngles(Angle(80, 0, 0))
        weapons.Revolver[1]:setParent(model.RightArm.Palm)
        local obj = setmetatable(
            {
                controller = controller,
                model = model,
                weapons = weapons,
                animations = animations,
                seat = seat,
                state = STATES.Idle,

                movementVelocity = Vector(),
                slamHeight = nil,
                slideDirection = nil,
                dashDirection = nil,
                dashRemain = 3.0,
                walljumpRemain = 3,
                slamjumpRemain = 3,
                driver = nil
            },
            V1
        )
        controller:addOnTick("movement", function(ctrl) obj:movement(ctrl) end)

        controller:addOnEnter("enter", function(_, ply)
            net.start("StartV1")
                net.writeTable(obj.model)
            net.send(ply)
        end)

        controller:addOnLeave("enter", function(_, ply)
            net.start("StopV1")
            net.send(ply)
        end)

        controller:addBind(IN_KEY.JUMP, function(ctrl) obj:jump(ctrl) end)
        controller:addBind(IN_KEY.SPEED, function(ctrl) obj:dash(ctrl) end)

        controller:addBind(
            IN_KEY.DUCK,
            function(ctrl)
                if controller:isOnGround() then
                    obj:startSlide(ctrl)
                else
                    obj:slam(ctrl)
                end
            end,
            function(ctrl)
                obj:stopSlide(ctrl)
            end
        )

        return obj
    end

    ---Get control direction. This direction is like dash direction or slide direction
    ---@return Vector?
    function V1:getControlDirection()
        local angs = self.controller.driver:getEyeAngles():setP(0)
        local axis = self.controller:getControlAxis()
        if !axis then return end
        if axis:getLength() == 0 then axis = Vector(1, 0, 0) end
        return angs:getForward() * axis.x + angs:getRight() * -axis.y
    end


    function V1:startSlide(ctrl)
        if self.state == STATES.Slide then return end
        if !ctrl:isOnGround() then return end
        self.slideDirection = self:getControlDirection()
        if !self.slideDirection then return end
        ctrl:setVelocity(self.slideDirection * SLIDESPEED)
        ctrl:setCameraHeight(CAMERAHEIGHT.SLIDE)
        self.state = STATES.Slide
        self.animations:play("slide")
        astrosounds.play("slide", Vector(), ctrl.body)
    end


    function V1:stopSlide(ctrl)
        if self.state ~= STATES.Slide then return end
        self.slideDirection = nil
        ctrl:setCameraHeight(CAMERAHEIGHT.DEFAULT)
        self.state = STATES.Idle
        self.animations:play("idle")
        astrosounds.stop("slide")
        astrosounds.play("ricochet", Vector(), ctrl.body)
    end


    function V1:movement(ctrl)
        local axis = ctrl:getControlAxis()
        if !axis then return end
        local rawAngs = ctrl.driver:getEyeAngles()
        self.model.Neck:setAngles(Angle(rawAngs.p / 6 - 10, rawAngs.y, 0))
        self.model.Head:setLocalAngles(Angle(rawAngs.p / 2 - 10, 0, 0))
        local angs = rawAngs:setP(0)
        local isOnGround = ctrl:isOnGround()
        local eyeTrace = ctrl:getEyeTrace()
        if !eyeTrace then return end
        local handAng = (eyeTrace.HitPos - self.model.RightArm.Leverage:getPos()):getAngle()
        self.model.RightArm.Leverage:setAngles(handAng + Angle(-90, 0, 0))

        local delta = game.getTickInterval()
        if self.state == STATES.Idle or self.state == STATES.Cling or self.state == STATES.WallJump then
            self.dashRemain = math.min(self.dashRemain + delta, 3)
            local axisRotated = axis:getRotated(angs)
            local velocity = ctrl:getVelocity()
            if !isOnGround then
                local pos = ctrl.body:getPos()
                local res = trace.line(pos, pos + axisRotated * ctrl.size.x, {ctrl.body})
                if !res.Hit or self.state == STATES.WallJump then
                    self.state = STATES.Idle
                    ctrl:addVelocity(Vector(0, 0, -GRAVITY * delta) + axisRotated * 20)
                else
                    self.state = STATES.Cling
                    ctrl:setVelocity(Vector(0, 0, math.max(velocity.z - GRAVITY * delta, -CLINGSPEED * delta)))
                end
            else
                self.walljumpRemain = 3
                if velocity.z < -80 and self.state ~= STATES.Slam then
                    astrosounds.play("land", Vector(), ctrl.body)
                end
                self.movementVelocity = math.lerpVector(0.5, self.movementVelocity, axisRotated * SPEED)
                ctrl:setVelocity(self.movementVelocity)
                if !axisRotated:isZero() and self.animations:get() ~= "movement" then
                    self.animations:play("movement", {function()
                        local dir = ctrl:getControlAxis()
                        if !dir then return Angle() end
                        return dir:setX(math.abs(dir.x)):getAngle()
                    end})
                elseif axisRotated:isZero() and self.animations:get() == "movement" then
                    self.animations:play("idle")
                end
            end
            local newAngs = math.lerpAngle(0.2, self.model.Main:getLocalAngles(), angs)
            self.model.Main:setLocalAngles(newAngs)
            local velo = velocity:getRotated(newAngs:setY(-newAngs.y))
            local ang = Angle(0, velo.x / 20, velo.z / -50)
            for i, wing in ipairs(self.model.LeftWings) do
                wing:setLocalAngles(ang / i)
            end
            for i, wing in ipairs(self.model.RightWings) do
                wing:setLocalAngles(ang / -i)
            end

        elseif self.state == STATES.Slide then
            local vel = ctrl:getVelocity()
            if vel:getLength() < 200 then
                self:stopSlide(ctrl)
                return
            end
            local slide = self.slideDirection * SLIDESPEED
            local move = (-angs:getRight() * axis.y * SLIDEMOVESPEED)
            local gravity = Vector(0, 0, vel.z - GRAVITY * delta)
            ctrl:setVelocity(slide + move + gravity)
            self.model.Main:setLocalAngles(math.lerpAngle(0.2, self.model.Main:getLocalAngles(), self.slideDirection:getAngle()))
        end
    end


    function V1:jump(ctrl)
        if self.state ~= STATES.Cling and !ctrl:isOnGround() then return end
        self:stopSlide(ctrl)

        -- Dash jump
        if self.state == STATES.Dash and self.dashRemain > 1 then
            self.state = STATES.Idle
            ctrl:setVelocity(self.dashDirection * DASHJUMPSPEED + Vector(0, 0, JUMP))
            self.dashRemain = self.dashRemain - 1

        -- Slam jump
        elseif self.state == STATES.Slam then
            self.state = STATES.Idle
            local slamHeight
            if self.slamjumpRemain == 0 then
                slamHeight = 0
            else
                slamHeight = self.slamHeight - ctrl.body:getPos().z
            end
            ctrl:setVelocity(Vector(0, 0, JUMP + slamHeight * 1.2))
            self.slamjumpRemain = self.slamjumpRemain - 1

        -- Wall jump
        elseif self.state == STATES.Cling then
            if self.walljumpRemain == 0 then return end
            self.walljumpRemain = self.walljumpRemain - 1
            local axis = ctrl:getControlAxis():getRotated(ctrl.driver:getEyeAngles():setP(0))
            self.state = STATES.WallJump
            ctrl:setVelocity(Vector(-axis.x * JUMP / 2, -axis.y * JUMP / 2, JUMP))

        -- Just a jump
        else
            ctrl:addVelocity(Vector(0, 0, JUMP))
        end

        astrosounds.play("jump", Vector(), self.controller.body)
    end


    function V1:slam(ctrl)
        if self.state == STATES.Slide or self.state == STATES.Slam then return end
        if ctrl:isOnGround() then return end
        self.state = STATES.Slam
        self.slamHeight = ctrl.body:getPos().z
        timer.create("slam", 0, 0, function()
            ctrl:setVelocity(Vector(0, 0, -SLAMSPEED))
            if ctrl:isOnGround() then
                ctrl:setVelocity(Vector(0, 0, 0))
                net.start("shake")
                net.send(ctrl.driver)
                astrosounds.play("land", Vector(), ctrl.body)
                timer.remove("slam")
                timer.simple(0.2, function()
                    if self.state ~= STATES.Slam then return end
                    self.state = STATES.Idle
                    self.slamHeight = nil
                    self.slamjumpRemain = 3
                end)
            end
        end)
    end


    function V1:dash(ctrl)
        if self.state == STATES.Dash or self.dashRemain < 1 then return end
        self.dashDirection = self:getControlDirection()
        if !self.dashDirection then return end
        self:stopSlide(ctrl)
        astrosounds.play("dash", Vector(), ctrl.body)
        local tw = Tween:new()
        tw:add(
            Fraction:new(DASHDURATION, nil,
                function()
                    if self.state ~= STATES.Dash then return end
                    ctrl:setVelocity(ctrl:getVelocity() / 12)
                    self.state = STATES.Idle
                end,
                function(t)
                    if self.state ~= STATES.Dash then t:remove() return end
                    ctrl:setVelocity(self.dashDirection * DASHSPEED)
                end
            )
        )
        tw:start()
        self.dashRemain = self.dashRemain - 1
        self.state = STATES.Dash
    end


    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    local v1 = V1:new(CHIPPOS + Vector(50, 0, 0), seat)
else
    require("ultrakill/src/controller.lua")
    require("ultrakill/src/model.lua")
    require("ultrakill/src/weapons.lua")
    local PLAYER = player()
    local model
    local shakeOffset = Vector()
    render.createRenderTarget("HUD")
    local hudMat = material.create("VertexLitGeneric")
    hudMat:setInt("$flags", 256)
    hudMat:setTextureRenderTarget("$basetexture", "HUD")
    local hudHolo = hologram.create(CHIPPOS, Angle(), "models/holograms/plane.mdl", Vector(0.3, 0.3, 0.3))
    if !hudHolo then return end
    hudHolo:suppressEngineLighting(true)
    hudHolo:setSubMaterial(0, "!" .. hudMat:getName())
    hudHolo:setColor(Color():setA(200))

    local function noDrawModel(modelTable, nodraw)
        for _, holo in pairs(modelTable) do
            if tostring(getmetatable(holo)) ~= "Entity" then
                noDrawModel(holo, nodraw)
                continue
            end
            local children = holo:getChildren()
            for _, child in ipairs(children) do
                if child:getModel() == "models/editor/axis_helper_thick.mdl" then continue end
                child:setNoDraw(nodraw)
            end
        end
    end

    net.receive("StartV1", function()
        model = net.readTable()
        noDrawModel(model, true)
    end)

    net.receive("StopV1", function()
        noDrawModel(model, false)
        model = {}
    end)

    hook.add("PlayerControllerCalcView", "V1", function(origin, angles)
        local slope = (PLAYER:keyDown(IN_KEY.MOVELEFT) and 1 or 0) - (PLAYER:keyDown(IN_KEY.MOVERIGHT) and 1 or 0)
        local angs = Angle(0, 0, slope * -1)
        return origin + shakeOffset, angles + angs, 120
    end)

    net.receive("shake", function()
        timer.create("shake", 0.01, 5, function()
            shakeOffset = Vector(math.rand(-1, 1), math.rand(-1, 1), math.rand(-1, 1)) * 3
        end)
        timer.simple(0.02 * 8, function()
            shakeOffset = Vector()
        end)
    end)
end
