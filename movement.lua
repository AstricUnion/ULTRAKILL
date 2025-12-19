---@name ULTRAKILL
---@author AstricUnion
---@shared
---@owneronly
---@include ultrakill/model.lua
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/hitbox.lua as hitbox
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/tweens.lua as tweens

local CHIPPOS = chip():getPos()

-- Constants --
local GRAVITY = 10
local SPEED = 500
local SLIDESPEED = 800
local SLIDEMOVESPEED = 100
local DASHSPEED = 30000
local DASHDURATION = 0.1
local DASHJUMPSPEED = 800
local SLAMSPEED = 2000
local JUMP = 500
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
    Slide = 4
}

if SERVER then
    --[[
    ---@class hitbox
    ---@module "astricunion.libs.hitbox"
    local hitbox = require("hitbox")
    ]]
    require("tweens")

    ---Mankind is dead. Blood is fuel. Hell is full.
    ---@class V1
    ---@field body Entity
    ---@field physobj PhysObj
    ---@field model table[Hologram]
    ---@field seat Vehicle
    ---@field camera Entity
    ---@field state STATES
    ---@field dashRemain number
    ---@field movementVelocity Vector
    ---@field slideDirection? Vector
    ---@field dashDirection? Vector
    ---@field driver? Player
    local V1 = {}
    V1.__index = V1

    ---@param pos Vector
    ---@param seat Vehicle
    ---@return V1?
    function V1:new(pos, seat)
        local body = prop.create(pos, Angle(), "models/props_c17/canister_propane01a.mdl")
        local physobj = body:getPhysicsObject()
        constraint.keepupright(body, Angle(), 0, 500)
        physobj:setMaterial("Player")
        body:setMass(1000)
        body:enableGravity(false)
        body:setColor(Color(0, 0, 0, 0))
        ---@module 'ultrakill.model'
        local model = require("ultrakill/model.lua")
        model.Main:setPos(pos)
        model.Main:setParent(body)
        local camera = hologram.create(pos + Vector(0, 0, CAMERAHEIGHT.DEFAULT), Angle(), "models/holograms/cube.mdl")
        if !camera then return end
        camera:setParent(body)
        local obj = setmetatable(
            {
                body = body,
                physobj = physobj,
                model = model,
                seat = seat,
                camera = camera,
                state = STATES.Idle,

                movementVelocity = Vector(),
                lastVelocity = Vector(),
                slideDirection = nil,
                dashDirection = nil,
                driver = nil
            },
            V1
        )
        obj:initHooks()
        return obj
    end


    function V1:initHooks()
        local id = "V1" .. tostring(self.body:entIndex())
        local hooks = {
            "Think",
            "PlayerEnteredVehicle",
            "PlayerLeaveVehicle",
            "KeyPress",
            "KeyRelease"
        }
        for _, name in ipairs(hooks) do
            hook.add(name, id, function(...) self[name](self, ...) end)
        end
    end

    ---Get vector of controls (GMod binded movement)
    function V1:getControlAxis()
        if !self.driver then return end
        local getAxis = function(negative, positive)
            return (self.driver:keyDown(positive) and 1 or 0) - (self.driver:keyDown(negative) and 1 or 0)
        end
        return Vector(
            getAxis(IN_KEY.BACK, IN_KEY.FORWARD),
            getAxis(IN_KEY.MOVERIGHT, IN_KEY.MOVELEFT),
            0
        )
    end


    ---Is V1 on ground
    ---@return boolean
    function V1:isOnGround()
        local pos = self.body:getPos()
        return trace.hull(
            pos,
            pos - Vector(0, 0, 8),
            Vector(-14, -14, 0),
            Vector(14, 14, 50),
            {self.body}
        ).Hit
    end


    ---Get control direction. This direction is like dash direction or slide direction
    ---@return Vector?
    function V1:getControlDirection()
        local angs = self.driver:getEyeAngles():setP(0)
        local axis = self:getControlAxis()
        if !axis then return end
        if axis:getLength() == 0 then axis = Vector(1, 0, 0) end
        return angs:getForward() * axis.x + angs:getRight() * -axis.y
    end


    function V1:startSlide()
        if self.state == STATES.Slide then return end
        local isOnGround = self:isOnGround()
        local gravity = Vector(0, 0, !isOnGround and (self.body:getVelocity().z - GRAVITY) or 0)
        self.slideDirection = self:getControlDirection()
        if !self.slideDirection then return end
        self.physobj:setVelocity(self.slideDirection * 1000 + gravity)
        self.camera:setPos(self.body:getPos() + Vector(0, 0, CAMERAHEIGHT.SLIDE))
        self.state = STATES.Slide
    end


    function V1:stopSlide()
        if self.state ~= STATES.Slide then return end
        self.slideDirection = nil
        if self:isOnGround() then
            self.physobj:setVelocity(Vector(0, 0, 0))
        end
        self.camera:setPos(self.body:getPos() + Vector(0, 0, CAMERAHEIGHT.DEFAULT))
        self.state = STATES.Idle
    end


    function V1:Think()
        self.physobj:setAngleVelocity(Vector())
        self.physobj:setAngles(Angle())
        local axis = self:getControlAxis()
        if !axis then return end
        local angs = self.driver:getEyeAngles():setP(0)
        self.model.Main:setAngles(angs)
        local isOnGround = self:isOnGround()
        if self.state == STATES.Idle then
            local axisRotated = axis:getRotated(angs)
            if !isOnGround then
                self.physobj:addVelocity(Vector(0, 0, -GRAVITY) + axisRotated * 12)
            else
                self.physobj:setVelocity(axisRotated * SPEED)
            end
        elseif self.state == STATES.Slide then
            local vel = self.physobj:getVelocity()
            if vel:getLength() < 100 then
                self:stopSlide()
                return
            end
            local slide = self.slideDirection * SLIDESPEED
            local move = (-angs:getRight() * axis.y * SLIDEMOVESPEED)
            local gravity = Vector(0, 0, vel.z - GRAVITY)
            self.physobj:setVelocity(slide + move + gravity)
        end
    end

    function V1:PlayerEnteredVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = ply
        enableHud(ply, true)
        ply:setViewEntity(self.camera)
        net.start("StartV1")
        net.writeEntity(self.camera)
        net.send(ply)
    end

    function V1:PlayerLeaveVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = nil
        ply:setViewEntity(nil)
        enableHud(ply, false)
        net.start("StopV1")
        net.writeEntity(self.camera)
        net.send(ply)
    end

    function V1:KeyPress(ply, key)
        if ply ~= self.driver then return end
        local isOnGround = self:isOnGround()

        -- Jump
        if key == IN_KEY.JUMP and isOnGround then
            self:stopSlide()
            -- Dash jump
            if self.state == STATES.Dash then
                self.state = STATES.Idle
                self.physobj:setVelocity(self.dashDirection * DASHJUMPSPEED + Vector(0, 0, JUMP))
            else
                self.physobj:addVelocity(Vector(0, 0, JUMP))
            end

        -- Slam
        elseif key == IN_KEY.DUCK and !isOnGround and self.state ~= STATES.Slide and self.state ~= STATES.Slam then
            self.state = STATES.Slam
            timer.create("slam", 0, 0, function()
                self.physobj:setVelocity(Vector(0, 0, -SLAMSPEED))
                if self:isOnGround() then
                    self.physobj:setVelocity(Vector(0, 0, 0))
                    net.start("shake")
                    net.send(self.driver)
                    self.state = STATES.Idle
                    timer.remove("slam")
                end
            end)

        -- Dash
        elseif key == IN_KEY.SPEED and self.state ~= STATES.Dash then
            self.dashDirection = self:getControlDirection()
            if !self.dashDirection then return end
            self:stopSlide()
            local tw = Tween:new()
            tw:add(
                Fraction:new(DASHDURATION, nil,
                    function()
                        if self.state == STATES.Idle then return end
                        self.physobj:setVelocity(Vector(0, 0, 0))
                        self.state = STATES.Idle
                    end,
                    function(t)
                        if self.state == STATES.Idle then t:remove() return end
                        self.physobj:setVelocity(self.dashDirection * DASHSPEED)
                    end
                )
            )
            tw:start()
            self.state = STATES.Dash

        -- Slide
        elseif key == IN_KEY.DUCK and isOnGround and self.state ~= STATES.Slide then
            self:startSlide()
        end
    end


    function V1:KeyRelease(ply, key)
        if ply ~= self.driver then return end
        -- Slide
        if key == IN_KEY.DUCK then
            self:stopSlide()
        end
    end


    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    local v1 = V1:new(CHIPPOS + Vector(50, 0, 0), seat)
else
    require("ultrakill/model.lua")
    local PLAYER = player()
    local shakeOffset = Vector()
    local slope = 0
    net.receive("StartV1", function()
        net.readEntity(function(camera)
            hook.add("CalcView", "V1Camera", function()
                local angs = PLAYER:getEyeAngles()
                slope = math.lerp(0.3, slope, (PLAYER:keyDown(IN_KEY.MOVELEFT) and 1 or 0) - (PLAYER:keyDown(IN_KEY.MOVERIGHT) and 1 or 0))
                return {
                    origin = camera:getPos() + shakeOffset + Vector(0, slope, 0):getRotated(angs),
                    angles = angs + Angle(0, 0, slope * -2)
                }
            end)
        end)
    end)

    net.receive("StopV1", function()
        hook.remove("CalcView", "V1Camera")
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
