---@name ULTRAKILL
---@author AstricUnion
---@shared
---@include ultrakill/src/movement.lua


local V1 = require("ultrakill/src/movement.lua")
if SERVER then
    local CHIPPOS = chip():getPos()
    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    V1:new(CHIPPOS + Vector(50, 0, 0), seat)
end
