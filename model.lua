---@name V1
---@author AstricUnion
---@shared

if SERVER then
    local holo = holograms.create(chip():getPos(), Angle(0, 0, 90), "models/Combine_Helicopter/helicopter_bomb01.mdl", Vector(50, 50, 50))
    holo:setParent(chip())
    hook.add("ClientInitialized", "", function(ply)
        net.start("OnClient")
        net.writeEntity(holo)
        net.send(ply)
    end)

    local step = 0
    hook.add("Think", "", function()
        step = step + 1
        holo:setPos(holo:getPos() + Vector(0, math.sin(math.rad(step))))
    end)
else

    local holo
    local model
    local texture = material.create("VertexLitGeneric")
    render.createRenderTarget("mesh")
    texture:setTextureURL("$basetexture", "https://www.dl.dropboxusercontent.com/scl/fi/da761zq8b7lbwzxb2dzqp/mainScaled.png?rlkey=auhx4anmxzxevugseysql1moq&st=yu7iwp7g&dl=0")

    local objdata = file.readInGame("data/starfall/ultrakill/models/v1.obj")
    if !objdata then return end

    local function doneLoadingMesh()
        holo:setMesh(model.Body)
        holo:setMeshMaterial(texture)
    end
    local loadmesh = coroutine.wrap(function()
        model = mesh.createFromObj(objdata, true)
        return true
    end)

    net.receive("OnClient", function()
        net.readEntity(function(ent)
            holo = ent
            hook.add("Think","loadingMesh",function()
                while chip():getQuotaAverage() < chip():getQuotaMax() / 2 do
                    if loadmesh() then
                        doneLoadingMesh()
                        hook.remove("think","loadingMesh")
                        return
                    end
                end
            end)
        end)
    end)
end
