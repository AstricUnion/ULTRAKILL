---@name Tweens
---@author AstricUnion
---@server

local function linear(t, b, c, d)
    return c * t / d + b
end

local CHIP = chip()
local pos = CHIP:getPos() + Vector(0, 0, 5)
local angle = CHIP:getAngles()
local endPos = pos + Vector(0, 10, 0)
local endAngle = angle + Angle(0, 180, 0)
local holo = hologram.create(pos, angle, "models/holograms/cube.mdl")
if !holo then return end
local process = 0
local change = endPos - pos
hook.add("Think", "", function()
    process = process + game.getTickInterval()
    local val = linear(3, pos, change, process)
    holo:setPos(val)
end)
