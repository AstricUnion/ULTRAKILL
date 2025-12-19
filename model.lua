---@name V1
---@author AstricUnion
---@shared
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
local holos = require("holos")

if SERVER then
    ---@class Holo
    local Holo = holos.Holo
    local Rig = holos.Rig
    local SubHolo = holos.SubHolo

    local function V1Part(partName, rigPos)
        return hologram.createPart(
            Holo(Rig(rigPos or Vector(), Angle())),
            Holo(SubHolo(Vector(), Angle(0, -90, 90), nil, Vector(47, 47, 47), nil, nil, nil, partName))
        )
    end

    local function Arm(prefix)
        local mirrorMult = prefix == "Left" and 1 or -1
        local parts = {
            Leverage = V1Part(prefix .. "Leverage", Vector(1, -8 * mirrorMult, 61)),
            Forearm = V1Part(prefix .. "Forearm", Vector(0.2, -9 * mirrorMult, 50.2)),
            Palm = V1Part(prefix .. "Palm", Vector(-2.5, -9 * mirrorMult, 37)),
            Fingers = V1Part(prefix .. "Fingers", Vector(-3.1, -10 * mirrorMult, 34)),
            Thumb = V1Part(prefix .. "Thumb", Vector(-5, -10 * mirrorMult, 36)),
        }
        parts.Forearm:setParent(parts.Leverage)
        parts.Palm:setParent(parts.Forearm)
        parts.Fingers:setParent(parts.Palm)
        parts.Thumb:setParent(parts.Palm)
        return parts
    end

    local function Leg(prefix)
        local mirrorMult = prefix == "Left" and 1 or -1
        local parts = {
            Hip = V1Part(prefix .. "Hip", Vector(1, -2.5 * mirrorMult, 43)),
            Calf = V1Part(prefix .. "Calf", Vector(0, -2.5 * mirrorMult, 26)),
            Foot = V1Part(prefix .. "Foot", Vector(3, -2.5 * mirrorMult, 5)),
        }
        parts.Calf:setParent(parts.Hip)
        parts.Foot:setParent(parts.Calf)
        return parts
    end

    local V1Model = {
        Main = Rig(Vector()),
        Body = V1Part("Body", Vector(1, 0, 43)),
        Head = V1Part("Head", Vector(4, 0, 71)),
        LeftArm = Arm("Left"),
        RightArm = Arm("Right"),
        LeftLeg = Leg("Left"),
        RightLeg = Leg("Right"),
    }

    V1Model.Head:setParent(V1Model.Body)
    V1Model.LeftArm.Leverage:setParent(V1Model.Body)
    V1Model.RightArm.Leverage:setParent(V1Model.Body)
    V1Model.LeftLeg.Hip:setParent(V1Model.Body)
    V1Model.RightLeg.Hip:setParent(V1Model.Body)
    V1Model.Body:setParent(V1Model.Main)

    return V1Model
else
    ---Holos to apply model. Index is name, value is holo
    local createdHolos = {}
    local model
    local texture = material.create("VertexLitGeneric")
    texture:setTextureURL("$basetexture", "https://www.dl.dropboxusercontent.com/scl/fi/da761zq8b7lbwzxb2dzqp/mainScaled.png?rlkey=auhx4anmxzxevugseysql1moq&st=yu7iwp7g&dl=1")

    local objdata = file.readInGame("data/starfall/ultrakill/models/v1.obj")
    if !objdata then return end

    local loadmesh = coroutine.wrap(function()
        model = mesh.createFromObj(objdata, true)
        return true
    end)

    local CHIP = chip()
    hook.add("Think", "LoadModel",function()
        while CHIP:getQuotaAverage() < CHIP:getQuotaMax() / 2 do
            if loadmesh() then
                for id, holo in pairs(createdHolos) do
                    holo:setMesh(model[id])
                    holo:setMeshMaterial(texture)
                end
                createdHolos = {}
                hook.remove("Think","LoadModel")
                return
            end
        end
    end)

    hook.add("HoloInitialized", "", function(id, holo)
        if !model then
            createdHolos[id] = holo
        else
            holo:setMesh(model[id])
            holo:setMeshMaterial(texture)
        end
    end)
end
