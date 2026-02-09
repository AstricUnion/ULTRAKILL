---@name V1 HUD
---@author AstricUnion
---@client

local function bevelXY(size, x, y, xd, yd, mirror)
    local coords = { {x = x, y = y + yd * size}, {x = x + xd * size, y = y} }
    if mirror then
        coords[1], coords[2] = coords[2], coords[1]
    end
    return coords
end

function render.drawRectBevel(size, x, y, w, h)
    local x2, y2 = x + w, y + h
    local bevels = {
        bevelXY(size, x, y, 1, 1, false),
        bevelXY(size, x2, y, -1, 1, true),
        bevelXY(size, x2, y2, -1, -1, false),
        bevelXY(size, x, y2, 1, -1, true),
    }
    local polys = {}
    for _, bevel in ipairs(bevels) do
        polys = table.add(polys, bevel)
    end
    render.drawPoly(polys)
end


---@class V1HUD
---@field stamina number
local V1HUD = {}
V1HUD.__index = V1HUD


---BOOT UP SEQUENCE READY
---
---FIRMWARE
---  LATEST VERSION (2112.08.06)
function V1HUD:new()
    return setmetatable(
        {
            stamina = 3,
            hp = 100,
            currentHp = 100
        },
        V1HUD
    )
end


local COLORS = {
    hp = Color(255, 93, 0),
    stamina = Color(0, 222, 255),
    bg = Color(0, 0, 0, 200)
}


function V1HUD:dash(stamina)
    self.stamina = stamina
end

function V1HUD:setHP(hp)
    self.hp = hp
end


function V1HUD:pushMask(mask)
    render.clearStencil()
    render.setStencilEnable(true)
    render.setStencilWriteMask(1)
    render.setStencilTestMask(1)
    render.setStencilFailOperation(STENCIL.REPLACE)
    render.setStencilPassOperation(STENCIL.ZERO)
    render.setStencilZFailOperation(STENCIL.ZERO)
    render.setStencilCompareFunction(STENCIL.NEVER)
    render.setStencilReferenceValue(1)
    mask()
    render.setStencilFailOperation(STENCIL.ZERO)
    render.setStencilPassOperation(STENCIL.REPLACE)
    render.setStencilZFailOperation(STENCIL.ZERO)
    render.setStencilCompareFunction(STENCIL.EQUAL)
    render.setStencilReferenceValue(1)
end


function V1HUD:popMask()
    render.setStencilEnable(false)
    render.clearStencil()
end

function V1HUD:PostDrawTranslucentRenderables()
    local pos = render.getEyePos()
    local ang = render.getAngles()
    local m = Matrix(
        ang + Angle(-90, 0, 20),
        pos + ang:getForward() * 100
            + ang:getRight() * -120
            + ang:getUp() * -60
    )
    m:setScale(Vector(0.1, -0.1))
    m:rotate(Angle(0, 90, 0))
    render.pushMatrix(m)
    do
        render.setColor(COLORS.bg)
        render.drawRectBevel(12, 0, 0, 512, 162)
        render.drawRectBevel(12, 528, 0, 162, 162)
        render.drawRectBevel(12, 0, -528, 528, 528)

        local gap = 8
        local width = 154
        self:pushMask(function()
            render.drawRectBevel(12, 16, 22, 480, 56)
            for i=0,2 do
                render.drawRectFast(16 + (i * (width + gap)), 82, width, 56)
            end
        end)
            render.setColor(COLORS.bg)
            render.drawRectBevel(12, 16, 82, 480, 56)
            render.drawRectBevel(12, 16, 22, 480, 56)

            render.setColor(COLORS.hp)
            self.currentHp = math.lerp(0.2, self.currentHp, self.hp)
            render.drawRectBevel(12, 16, 22, 480 * (self.currentHp / 100), 56)

            render.setColor(COLORS.stamina)
            render.drawRectBevel(12, 16, 82, 480 * (self.stamina / 3), 56)
        self:popMask()
    end
    render.popMatrix()
end

function V1HUD:Think()
    if self.stamina < 3 then
        self.stamina = math.min(self.stamina + game.getRealTickInterval(), 3)
    end
end


return V1HUD
