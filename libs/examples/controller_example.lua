---@name Player controller example
---@author AstricUnion
---@shared

---@class PlayerController
---@module 'controller'
---@include ultrakill/libs/controller.lua
local PlayerController = require("ultrakill/libs/controller.lua")

if SERVER then
    -- Very easy controller example
    local GRAVITY = physenv.getGravity()

    local CHIPPOS = chip():getPos()
    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    local controller = PlayerController:new(CHIPPOS + Vector(50, 0, 0), seat, 80, Vector(24, 24, 80))
    if !controller then return end

    controller:addOnTick("move", function(ctrl)
        if !ctrl.driver then return end
        if !ctrl:isOnGround() then
            ctrl:addVelocity(-GRAVITY * game.getTickInterval())
        else
            local speed = Vector()
            local axis = ctrl:getControlAxis()
            if axis then
                local angs = ctrl.driver:getEyeAngles():setP(0)
                speed = axis:getRotated(angs) * 500
            end
            ctrl:setVelocity(speed)
        end
    end)

    controller:addBind(IN_KEY.JUMP, function(ctrl)
        if !ctrl:isOnGround() then return end
        ctrl:addVelocity(Vector(0, 0, 1000))
    end)
end
