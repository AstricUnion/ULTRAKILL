---@name V1 animations
---@author AstricUnion
---@include ultrakill/src/model.lua
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/tweens.lua as tweens
---@module 'astricunion.libs.tweens'
require("tweens")


if SERVER then
    ---@class animations
    local animations = {}
    animations.currentTween = nil
    animations.currentAnimation = nil

    ---Default, idle pose
    function animations.defaultPose(model)
        if animations.currentTween then
            animations.currentTween:remove()
        end
        model.Pelvis:setLocalPos(Vector(-1, 0, 40))

        model.RightLeg.Foot:setLocalAngles(Angle(-30, 0, 0))
        model.RightLeg.Calf:setLocalAngles(Angle(50, 0, 0))
        model.RightLeg.Hip:setLocalAngles(Angle(0, -10, -10))

        model.LeftLeg.Foot:setLocalAngles(Angle(0, 0, 0))
        model.LeftLeg.Calf:setLocalAngles(Angle(50, 0, 0))
        model.LeftLeg.Hip:setLocalAngles(Angle(-50, 10, 0))

        model.LeftArm.Palm:setLocalAngles(Angle(0, 0, 0))
        model.LeftArm.Forearm:setLocalAngles(Angle(0, 0, 0))
        model.LeftArm.Leverage:setLocalAngles(Angle(0, 0, 0))

        model.Body:setLocalAngles(Angle(0, 0, 0))
        model.Pelvis:setLocalAngles(Angle(0, 0, 0))

        model.Neck:setLocalAngles(Angle(0, 0, 0))
        model.Head:setLocalAngles(Angle(0, 0, 0))

        model.LeftWings[1]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[2]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[3]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[4]:setLocalAngles(Angle(0, 0, 0))

        model.RightWings[1]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[2]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[3]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[4]:setLocalAngles(Angle(0, 0, 0))

        local tw = Tween:new()
        tw:add(
            Param:new(0.5, model.LeftLeg.Hip, PROPERTY.LOCALANGLES, Angle(-40, 10, 0), math.easeOutSine),
            Param:new(0.5, model.LeftLeg.Calf, PROPERTY.LOCALANGLES, Angle(40, 0, 0), math.easeOutSine),
            Param:new(0.5, model.RightLeg.Calf, PROPERTY.LOCALANGLES, Angle(40, 0, 0), math.easeOutSine),
            Param:new(0.5, model.Pelvis, PROPERTY.LOCALPOS, Vector(-1, 0, 41), math.easeOutSine)
        )
        tw:add(
            Param:new(0.5, model.LeftLeg.Hip, PROPERTY.LOCALANGLES, Angle(-50, 10, 0), math.easeOutSine),
            Param:new(0.5, model.LeftLeg.Calf, PROPERTY.LOCALANGLES, Angle(50, 0, 0), math.easeOutSine),
            Param:new(0.5, model.RightLeg.Calf, PROPERTY.LOCALANGLES, Angle(50, 0, 0), math.easeOutSine),
            Param:new(0.5, model.Pelvis, PROPERTY.LOCALPOS, Vector(-1, 0, 39), math.easeOutSine)
        )
        tw:setLoop(true)
        tw:start()
        animations.currentTween = tw
        animations.currentAnimation = "idle"
    end


    ---Movement, when V1 moves
    ---@param getMovementDirection fun()
    function animations.movement(model, getMovementDirection)
        if animations.currentTween then
            animations.currentTween:remove()
        end
        model.Pelvis:setLocalPos(Vector(-1, 0, 41))

        model.RightLeg.Foot:setLocalAngles(Angle(-20, 0, 0))
        model.RightLeg.Calf:setLocalAngles(Angle(20, 0, 0))
        model.RightLeg.Hip:setLocalAngles(Angle(0, 0, 0))

        model.LeftLeg.Foot:setLocalAngles(Angle(0, 0, 0))
        model.LeftLeg.Calf:setLocalAngles(Angle(20, 0, 0))
        model.LeftLeg.Hip:setLocalAngles(Angle(-20, 0, 0))

        model.LeftArm.Palm:setLocalAngles(Angle(0, 0, 0))
        model.LeftArm.Forearm:setLocalAngles(Angle(0, 0, 0))
        model.LeftArm.Leverage:setLocalAngles(Angle(0, 0, 0))

        model.Body:setLocalAngles(Angle(0, 0, 0))
        model.Pelvis:setLocalAngles(Angle(0, 0, 0))

        model.Neck:setLocalAngles(Angle(0, 0, 0))
        model.Head:setLocalAngles(Angle(0, 0, 0))

        model.LeftWings[1]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[2]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[3]:setLocalAngles(Angle(0, 0, 0))
        model.LeftWings[4]:setLocalAngles(Angle(0, 0, 0))

        model.RightWings[1]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[2]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[3]:setLocalAngles(Angle(0, 0, 0))
        model.RightWings[4]:setLocalAngles(Angle(0, 0, 0))

        local tw = Tween:new()
        local bodyAngle = function()
            return -getMovementDirection()
        end

        tw:add(
            Param:new(0.2, model.LeftLeg.Hip, PROPERTY.LOCALANGLES, Angle(-80, 0, 0), math.easeOutSine),
            Param:new(0.2, model.LeftLeg.Calf, PROPERTY.LOCALANGLES, Angle(80, 0, 0), math.easeOutSine),

            Param:new(0.1, model.RightLeg.Hip, PROPERTY.LOCALANGLES, Angle(40, 0, 0), math.easeOutSine),
            Param:new(0.1, model.RightLeg.Calf, PROPERTY.LOCALANGLES, Angle(0, 0, 0), math.easeOutSine),

            Param:new(0.2, model.Pelvis, PROPERTY.LOCALANGLES, getMovementDirection, math.easeOutSine),
            Param:new(0.2, model.Body, PROPERTY.LOCALANGLES, bodyAngle, math.easeOutSine)
        )
        tw:add(
            Param:new(0.1, model.LeftLeg.Hip, PROPERTY.LOCALANGLES, Angle(40, 0, 0), math.easeOutSine),
            Param:new(0.1, model.LeftLeg.Calf, PROPERTY.LOCALANGLES, Angle(0, 0, 0), math.easeOutSine),

            Param:new(0.2, model.RightLeg.Hip, PROPERTY.LOCALANGLES, Angle(-80, 0, 0), math.easeOutSine),
            Param:new(0.2, model.RightLeg.Calf, PROPERTY.LOCALANGLES, Angle(80, 0, 0), math.easeOutSine)
        )
        tw:setLoop(true)
        tw:start()
        animations.currentTween = tw
        animations.currentAnimation = "movement"
    end


    ---Slide pose
    function animations.slidePose(model)
        if animations.currentTween then
            animations.currentTween:remove()
        end
        model.Pelvis:setLocalPos(Vector(0, 0, 2))

        model.RightLeg.Foot:setLocalAngles(Angle(0, 0, 0))
        model.RightLeg.Calf:setLocalAngles(Angle(0, 0, 0))
        model.RightLeg.Hip:setLocalAngles(Angle(-50, 0, 0))

        model.LeftLeg.Foot:setLocalAngles(Angle(45, 0, 0))
        model.LeftLeg.Calf:setLocalAngles(Angle(120, 0, 0))
        model.LeftLeg.Hip:setLocalAngles(Angle(-135, 0, 90))

        model.LeftArm.Palm:setLocalAngles(Angle(10, -90, 10))
        model.LeftArm.Forearm:setLocalAngles(Angle(-135, 0, 180))
        model.LeftArm.Leverage:setLocalAngles(Angle(60, -90, 0))

        model.Body:setLocalAngles(Angle(-8, 75, 11))
        model.Pelvis:setLocalAngles(Angle(-45, 0, 0))

        model.Neck:setLocalAngles(Angle(30, -50, 0))
        model.Head:setLocalAngles(Angle(0, -30, 0))

        model.LeftWings[1]:setLocalAngles(Angle(0, 30, 60))
        model.LeftWings[2]:setLocalAngles(Angle(0, 20, 60))
        model.LeftWings[3]:setLocalAngles(Angle(0, 10, 60))
        model.LeftWings[4]:setLocalAngles(Angle(0, 0, 60))

        model.RightWings[1]:setLocalAngles(Angle(0, -30, 20))
        model.RightWings[2]:setLocalAngles(Angle(0, -20, 20))
        model.RightWings[3]:setLocalAngles(Angle(0, -10, 20))
        model.RightWings[4]:setLocalAngles(Angle(0, 0, 20))
        animations.currentAnimation = "slide"
    end

    return animations


    --[[ To test
    local CHIPPOS = chip():getPos()
    ---@module 'ultrakill.src.model'
    local model = require("ultrakill/src/model.lua")
    model.Main:setAngles(Angle(0, 90, 0))
    animations.movement(CHIPPOS, model)
else
    require("ultrakill/src/model.lua")]]
end


