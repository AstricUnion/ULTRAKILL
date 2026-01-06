---@name V1 HUD
---@author AstricUnion
---@client
---@owneronly


---@class V1HUD
local V1HUD = {}
V1HUD.__index = V1HUD


---BOOT UP SEQUENCE READY
---
---FIRMWARE
---  LATEST VERSION (2112.08.06)
function V1HUD:new()

    local background = hologram.create(Vector(), Angle(), "models/holograms/plane.mdl", Vector(-0.9, -0.9, 1))
    if !background then return end
    render.createRenderTarget("background")
    local backgroundMat = material.create("VertexLitGeneric")
    backgroundMat:setInt("$flags", 256)
    backgroundMat:setTextureRenderTarget("$basetexture", "background")
    background:setSubMaterial(0, "!" .. backgroundMat:getName())
    background:suppressEngineLighting(true)
    background:setColor(Color(255, 255, 255, 180))

    local elements = hologram.create(Vector(0, 0, 0.01), Angle(), "models/holograms/plane.mdl", Vector(-0.9, -0.9, 1))
    if !elements then return end
    render.createRenderTarget("elements")
    local elementsMat = material.create("VertexLitGeneric")
    elementsMat:setInt("$flags", 256)
    elementsMat:setTextureRenderTarget("$basetexture", "elements")
    elements:setSubMaterial(0, "!" .. elementsMat:getName())
    elements:suppressEngineLighting(true)
    elements:setParent(background)

    return setmetatable(
        {
            background = background
        },
        V1HUD
    )
end


function V1HUD:RenderOffscreen()
    render.selectRenderTarget("background")
    do
        render.clear(Color(0, 0, 0, 0))
        render.setColor(Color(0, 0, 0))
        render.drawRoundedBox(8, 0, 0, 512, 162)
    end
    render.selectRenderTarget("elements")
    do
        render.clear(Color(0, 0, 0, 0))
        render.setColor(Color(255, 0, 0))
        render.drawRoundedBox(16, 16, 16, 480, 56)

        render.setColor(Color(0, 255, 255))
        render.drawRoundedBoxEx(16, 16, 88, 150, 56, true, false, true, false)
        render.drawRect(176, 88, 150, 56)
        render.drawRoundedBoxEx(16, 336, 88, 150, 56, false, true, false, true)
    end
    render.selectRenderTarget()
end


function V1HUD:CalcView(origin, angles)
    self.background:setPos(origin + angles:getForward() * 10 + angles:getRight() * -7 + angles:getUp() * -10)
    self.background:setAngles(angles + Angle(-90, 0, 20))
end


enableHud(nil, true)
local hud = V1HUD:new()
if !hud then return end
hook.add("CalcView", "", function(origin, angles)
    hud:CalcView(origin, angles)
end)
hook.add("RenderOffscreen", "", function()
    hud:RenderOffscreen()
end)
