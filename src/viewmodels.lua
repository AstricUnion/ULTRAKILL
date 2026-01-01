---@name Viewmodels
---@author AstricUnion
---@client
---@owneronly
---@include ultrakill/src/mesh.lua

enableHud(nil, true)

local parent = hologram.create(chip():getPos(), Angle(0, 0, 0), "models/editor/axis_helper_thick.mdl")
if !parent then return end
parent:setNoDraw(true)
local holo = hologram.create(chip():getPos(), Angle(0, 90, 90), "models/Combine_Helicopter/helicopter_bomb01.mdl")
if !holo then return end
holo:setParent(parent)


---@class CustomMesh
local CustomMesh = require("ultrakill/src/mesh.lua")

---Holos to apply model. Index is name, value is holo
local GITHUB_URL = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/main/"

local revolverTexture = material.create("VertexLitGeneric")
revolverTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/weapons/revolverDiff_9.png")

CustomMesh:new(GITHUB_URL .. "models/weapons.obj")
    :addMaterial("Revolver", revolverTexture)
    :addMaterial("RevolverCylinder", revolverTexture)
    :init(function(self) self:setTo("Revolver", holo) end)

hook.add("CalcView", "Viewmodel", function(origin, angles)
    parent:setPos(origin + angles:getForward() * 15 + angles:getRight() * 5 + angles:getUp() * -5)
    parent:setAngles(angles)
end)

net.receive("SendWeapons", function()
    weapons = net.readTable()
end)
