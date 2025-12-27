---@name V1 weapons
---@author AstricUnion
---@shared
---@include astricunion/libs/holos.lua
local holos = require("astricunion/libs/holos.lua")

if SERVER then
    ---@class Holo
    local Holo = holos.Holo
    local Rig = holos.Rig
    local SubHolo = holos.SubHolo

    local function V1Part(partName, rigPos)
        return hologram.createPart(
            Holo(Rig(rigPos or Vector(), Angle())),
            Holo(SubHolo(Vector(), Angle(0, -90, 0), "models/props_phx/construct/metal_tubex2.mdl", Vector(1, 1, 1), true, nil, nil, partName))
        )
    end

    ---@class V1Weapons
    local V1Weapons = {
        Main = Rig(Vector()),
        Revolver = V1Part("Revolver", Vector()),
    }
else
    ---Holos to apply model. Index is name, value is holo
    local createdHolos = {}
    local model
    local GITHUB_URL = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/main/"

    local mainTexture = material.create("VertexLitGeneric")
    mainTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/weapons/revolverDiff_9.png")

    http.get(GITHUB_URL .. "models/weapons.obj", function(obj)
        if !obj then return end
        local loadmesh = coroutine.wrap(function()
            model = mesh.createFromObj(obj, true)
            printTable(model)
            return true
        end)

        local CHIP = chip()
        hook.add("Think", "LoadModel",function()
            while CHIP:getQuotaAverage() < CHIP:getQuotaMax() / 2 do
                if loadmesh() then
                    for id, holo in pairs(createdHolos) do
                        ---@cast holo Hologram
                        holo:setMesh(model[id])
                        local res, _, _ = string.find(id, "Wing")
                        holo:setMeshMaterial(res and wingTexture or mainTexture)
                    end
                    createdHolos = {}
                    hook.remove("Think","LoadModel")
                    return
                end
            end
        end)
    end)


    hook.add("HoloInitialized", "", function(id, holo)
        if !model then
            createdHolos[id] = holo
        else
            holo:setMesh(model[id])
            local res, _, _ = string.find(id, "Wing")
            holo:setMeshMaterial(res and wingTexture or mainTexture)
        end
    end)
end
