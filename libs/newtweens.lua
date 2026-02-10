---@name Tweens
---@author AstricUnion
---@server

local function inOutSine(t, b, c, d) return b + c * math.easeInOutSine(t / d) end

local CHIP = chip()
local pos = CHIP:getPos() + Vector(0, 0, 5)
local angle = CHIP:getAngles()
local endPos = pos + Vector(0, 50, 0)
local endAngle = angle + Angle(0, 180, 0)
local holo = hologram.create(pos, angle, "models/holograms/cube.mdl")
if !holo then return end
local process = 0
local changePos = endPos - pos
local changeAng = endAngle - angle
hook.add("Think", "", function()
    process = process + game.getTickInterval()
    local valPos = inOutSine(process, pos, changePos, 1)
    local valAng = inOutSine(process, angle, changeAng, 1)
    if process >= 1 then hook.remove("Think", "") end
    holo:setPos(valPos)
    holo:setAngles(valAng)
end)
