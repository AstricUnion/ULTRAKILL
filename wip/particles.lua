---@name V1 particles
---@author AstricUnion
---@client


local mat = material.create("VertexLitGeneric")
local CHIPPOS = chip():getPos()
local wind = particle.create(CHIPPOS, false)
timer.create("newparticles", 0.05, 0, function()
    local ang = math.rand(-math.pi, math.pi)
    local part = wind:add(
        mat,
        CHIPPOS + Vector(math.sin(ang) * 20, math.cos(ang) * 20, 0),
        1, 1,
        10, 10,
        1, 1,
        1
    )
    part:setVelocity(Vector(0, 0, 200))
    part:setLighting(false)
    part:setColor(Color(100, 100, 100, 100))
end)


