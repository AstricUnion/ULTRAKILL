---@name V1 HUD
---@author AstricUnion
---@client

local function bevelXY(size, x, y, xd, yd)
    return { {x = x, y = y + yd * size}, {x = x + xd * size, y = y} }
end

function render.drawRectBevel(size, x, y, w, h)
    local x2, y2 = x + w, y + h
    local bevels = {
        bevelXY(size, x, y, 1, 1),
        bevelXY(size, x2, y, -1, 1),
        bevelXY(size, x2, y2, -1, -1),
        bevelXY(size, x, y2, 1, -1),
    }
    local polys = {}
    for bevelId, bevel in ipairs(bevels) do
        local i = #polys+1
        if bevelId % 2 == 0 then
            polys[i], polys[i+1] = bevel[2], bevel[1]
        else
            polys[i], polys[i+1] = bevel[1], bevel[2]
        end
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
            stamina = 3
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
        pos + ang:getForward() * 60
            + ang:getRight() * -100
            + ang:getUp() * -50
    )
    m:setScale(Vector(0.1, -0.1))
    m:rotate(Angle(0, 90, 0))
    render.pushMatrix(m)
    do
        render.setColor(COLORS.bg)
        render.drawRectBevel(12, 0, 0, 512, 162)
        render.drawRectBevel(12, 16, 22, 480, 56)
        render.setColor(COLORS.hp)
        render.drawRectBevel(12, 16, 22, 480, 56)

        local gap = 8
        local width = 154
        self:pushMask(function()
            for i=0,2 do
                render.drawRectFast(16 + (i * (width + gap)), 82, width, 56)
            end
        end)
        render.setColor(COLORS.bg)
        render.drawRectBevel(12, 16, 82, 480, 56)
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
