---@name V1
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
            Holo(Rig(rigPos or Vector(), Angle(), true)),
            Holo(SubHolo(Vector(), Angle(0, -90, 90), nil, Vector(47, 47, 47), nil, nil, nil, partName))
        )
    end

    local function Arm(prefix)
        local mirrorMult = prefix == "Left" and 1 or -1
        local parts = {
            Leverage = V1Part(prefix .. "Leverage", Vector(-1, 8 * mirrorMult, 61)),
            Forearm = V1Part(prefix .. "Forearm", Vector(-0.2, 9.2 * mirrorMult, 50.2)),
            Palm = V1Part(prefix .. "Palm", Vector(2.5, 9 * mirrorMult, 37)),
            Fingers = V1Part(prefix .. "Fingers", Vector(3.1, 10 * mirrorMult, 34)),
            Thumb = V1Part(prefix .. "Thumb", Vector(5, 10 * mirrorMult, 36)),
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
            Hip = V1Part(prefix .. "Hip", Vector(0, 5 * mirrorMult, 43)),
            Calf = V1Part(prefix .. "Calf", Vector(0, 2.5 * mirrorMult, 26)),
            Foot = V1Part(prefix .. "Foot", Vector(-3, 2.5 * mirrorMult, 5)),
        }
        parts.Calf:setParent(parts.Hip)
        parts.Foot:setParent(parts.Calf)
        return parts
    end

    local function Wings(prefix)
        -- local mirrorMult = prefix == "Left" and 1 or -1
        local parts = {
            V1Part("Wing" .. prefix .. "1", Vector()),
            V1Part("Wing" .. prefix .. "2", Vector()),
            V1Part("Wing" .. prefix .. "3", Vector()),
            V1Part("Wing" .. prefix .. "4", Vector()),
        }
        return parts
    end

    local V1Model = {
        Main = Rig(Vector()),
        Body = V1Part("Body", Vector(-1, 0, 43)),
        Head = V1Part("Head", Vector(-4, 0, 71)),
        LeftArm = Arm("Left"),
        RightArm = Arm("Right"),
        LeftLeg = Leg("Left"),
        RightLeg = Leg("Right"),
        LeftWings = Wings("Left"),
        RightWings = Wings("Right")
    }

    V1Model.Head:setParent(V1Model.Body)
    V1Model.LeftArm.Leverage:setParent(V1Model.Body)
    V1Model.RightArm.Leverage:setParent(V1Model.Body)
    V1Model.LeftLeg.Hip:setParent(V1Model.Body)
    V1Model.RightLeg.Hip:setParent(V1Model.Body)
    V1Model.Body:setParent(V1Model.Main)
    for _, wing in ipairs(V1Model.LeftWings) do
        wing:setParent(V1Model.Body)
    end
    for _, wing in ipairs(V1Model.RightWings) do
        wing:setParent(V1Model.Body)
    end

    return V1Model
else
    ---Holos to apply model. Index is name, value is holo
    local createdHolos = {}
    local model
    local GITHUB_URL = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/main/"

    local mainTexture = material.create("VertexLitGeneric")
    mainTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/main.png")

    local wingTexture = material.create("VertexLitGeneric")
    wingTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/wing.png")

    http.get(GITHUB_URL .. "models/v1.obj", function(obj)
        if !obj then return end
        local loadmesh = coroutine.wrap(function()
            model = mesh.createFromObj(obj, true)
            return true
        end)

        local CHIP = chip()
        hook.add("Think", "LoadModel",function()
            while CHIP:getQuotaAverage() < CHIP:getQuotaMax() / 2 do
                if loadmesh() then
                    for id, holo in pairs(createdHolos) do
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
