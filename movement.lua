---@name ULTRAKILL
---@author AstricUnion
---@shared
---@owneronly

local CHIPPOS = chip():getPos()

-- Constants --
local GRAVITY = 20
local SPEED = 800
local SLIDESPEED = 1000
local SLIDEMOVESPEED = 100
local DASHSPEED = 7000
local DASHDURATION = 0.05
local SLAMSPEED = 2000
local CAMERAHEIGHT = {
    DEFAULT = 60,
    SLIDE = 20
}

if SERVER then
    --[[
    ---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/hitbox.lua as hitbox
    ---@class hitbox
    ---@module "astricunion.libs.hitbox"
    local hitbox = require("hitbox")
    ]]

    ---Mankind is dead. Blood is fuel. Hell is full.
    ---@class V1
    ---@field body Entity
    ---@field physobj PhysObj
    ---@field seat Vehicle
    ---@field camera Entity
    ---@field movementVelocity Vector
    ---@field slideDirection? Vector
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
        local camera = hologram.create(pos + Vector(0, 0, CAMERAHEIGHT.DEFAULT), Angle(), "models/holograms/cube.mdl")
        if !camera then return end
        camera:setParent(body)
        local obj = setmetatable(
            {
                body = body,
                physobj = physobj,
                seat = seat,
                camera = camera,
                movementVelocity = Vector(),
                slideDirection = nil,
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
            Vector(-12, -12, 0),
            Vector(12, 12, 10),
            {self.body}
        ).Hit
    end


    function V1:startSlide()
        local angs = self.driver:getEyeAngles():setP(0)
        local axis = self:getControlAxis()
        if !axis then return end
        if axis:getLength() == 0 then
            axis = Vector(1, 0, 0)
        end
        self.slideDirection = angs:getForward() * axis.x + angs:getRight() * -axis.y
        local isOnGround = self:isOnGround()
        local gravity = Vector(0, 0, !isOnGround and (self.body:getVelocity().z - GRAVITY) or 0)
        self.physobj:setVelocity(self.slideDirection * 1000 + gravity + self.slideDirection:getRotated(Angle(0, 90, 0)) * axis.y * 100)
        self.camera:setPos(self.body:getPos() + Vector(0, 0, CAMERAHEIGHT.SLIDE))
    end


    function V1:stopSlide()
        self.slideDirection = nil
        if self:isOnGround() then
            self.physobj:setVelocity(Vector(0, 0, 0))
        end
        self.camera:setPos(self.body:getPos() + Vector(0, 0, CAMERAHEIGHT.DEFAULT))
    end


    function V1:Think()
        self.physobj:setAngleVelocity(Vector())
        local isOnGround = self:isOnGround()
        local gravity = Vector(0, 0, !isOnGround and (self.body:getVelocity().z - GRAVITY) or 0)
        local axis = self:getControlAxis()
        if !axis then return end
        local angs = self.driver:getEyeAngles():setP(0)
        if !self.slideDirection then
            local axisRotated = axis:getRotated(angs)
            self.movementVelocity = math.lerpVector(0.3, self.movementVelocity, axisRotated * SPEED / (isOnGround and 1 or 2))
            self.physobj:setVelocity(self.movementVelocity + gravity)
        else
            if self.physobj:getVelocity():setZ(0):getLength() < 200 then
                self:stopSlide()
                return
            end
            self.physobj:setVelocity(self.slideDirection * SLIDESPEED + gravity + self.slideDirection:getRotated(Angle(0, 90, 0)) * axis.y * SLIDEMOVESPEED)
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
        if key == IN_KEY.JUMP and isOnGround and !self.slideDirection then
            self.physobj:addVelocity(Vector(0, 0, 500))

        -- Slam
        elseif key == IN_KEY.DUCK and !isOnGround and !self.slideDirection then
            timer.create("slam", 0, 0, function()
                self.physobj:setVelocity(Vector(0, 0, -SLAMSPEED))
                if self:isOnGround() then
                    self.physobj:setVelocity(Vector(0, 0, 0))
                    net.start("shake")
                    net.send(self.driver)
                    timer.remove("slam")
                end
            end)

        -- Slide
        elseif key == IN_KEY.DUCK and isOnGround and !self.slideDirection then
            self:startSlide()

        -- Dash
        elseif key == IN_KEY.SPEED and !self.slideDirection then
            local angs = self.driver:getEyeAngles():setP(0)
            local axis = self:getControlAxis()
            if !axis then return end
            if axis:getLength() == 0 then
                axis = Vector(1, 0, 0)
            end
            local dashDirection = angs:getForward() * axis.x + angs:getRight() * -axis.y
            timer.create("dash", 0, DASHDURATION / 0.01, function()
                self.physobj:addVelocity(dashDirection * DASHSPEED)
            end)
        end
    end


    function V1:KeyRelease(ply, key)
        if ply ~= self.driver then return end
        -- Slide
        if key == IN_KEY.DUCK and self.slideDirection then
            self:stopSlide()
        end
    end


    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    local v1 = V1:new(CHIPPOS + Vector(50, 0, 0), seat)
else
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
