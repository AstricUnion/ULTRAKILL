---@name V1 animations
---@author AstricUnion
---@include ultrakill/src/model.lua
---@module 'ultrakill.src.model'
local model = require("ultrakill/src/model.lua")


if SERVER then
    local CHIPPOS = chip():getPos()

    local function slidePose()
        model.Body:setPos(CHIPPOS + Vector(0, 0, 2))
        model.Body:setLocalAngles(Angle(-45, 0, 0))
        model.RightLeg.Hip:setAngles(Angle(-90, 0, 0))
        model.LeftLeg.Hip:setAngles(Angle(180, 0, 90))
        model.LeftLeg.Calf:setAngles(Angle(180, -120, 90))
        model.LeftLeg.Foot:setAngles(Angle(180, -180, 90))
    end

    slidePose()
end


