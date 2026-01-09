---@name Weapons
---@author AstricUnion
---@shared
---@include astricunion/libs/holos.lua
---@include ultrakill/libs/mesh.lua
local holos = require("astricunion/libs/holos.lua")

---@class Holo
local Holo = holos.Holo
local Rig = holos.Rig
local SubHolo = holos.SubHolo

if SERVER then
    local function WeaponPart(partName, rigPos)
        return hologram.createPart(
            Holo(Rig(rigPos or Vector(), Angle())),
            Holo(SubHolo(Vector(), Angle(0, 90, 90), "models/Combine_Helicopter/helicopter_bomb01.mdl", Vector(1, 1, 1), true, nil, nil, partName))
        )
    end

    ---@class V1Weapons
    local V1Weapons = {
        Main = Rig(Vector()),
        Revolver = {
            WeaponPart("Revolver", Vector(-3, 0, -2)),
            WeaponPart("RevolverCylinder", Vector(0, 0, 1.65))
        }
    }

    V1Weapons.Revolver[2]:setParent(V1Weapons.Revolver[1])

    return V1Weapons
else
    ---@class CustomMesh
    local CustomMesh = require("ultrakill/libs/mesh.lua")

    ---Holos to apply model. Index is name, value is holo
    local createdHolos = {}
    ---@type Hologram
    local viewmodelRig = Rig()
    local viewmodel = SubHolo(nil, Angle(0, 90, 90), "models/Combine_Helicopter/helicopter_bomb01.mdl", nil, true, nil, nil)
    viewmodel:setParent(viewmodelRig)
    local GITHUB_URL = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/main/"

    local revolverTexture = material.create("VertexLitGeneric")
    revolverTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/weapons/revolverDiff_9.png")

    local mesh = CustomMesh:new(GITHUB_URL .. "models/weapons.obj")
        :addMaterial("Revolver", revolverTexture)
        :addMaterial("RevolverCylinder", revolverTexture)
        :init(function(self)
            for id, holo in pairs(createdHolos) do
                self:setTo(id, holo)
            end
            self:setTo("Revolver", viewmodel)
            createdHolos = {}
        end)


    hook.add("HoloInitialized", "Weapons", function(id, holo)
        if !mesh:isInitialized() then
            createdHolos[id] = holo
        else
            mesh:setTo(id, holo)
        end
    end)

    return viewmodelRig, viewmodel
end
