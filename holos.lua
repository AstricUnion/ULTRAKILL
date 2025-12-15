---@name V1
---@author AstricUnion
---@server
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/holos.lua as holos
require("holos")

---@param mirror boolean
local function headBody(mirror)
    local mirrorMult = mirror and 1 or -1
    local rig = Rig(Vector(0, 0, 70), Angle(0, 0, 0))
    if !rig then return end
    for i=0, 5 do
        SubHolo(
            Vector(0, 3 * mirrorMult, 70), Angle(0, 0, 0),
            "models/holograms/cube.mdl", Vector(1.2, 0.15, 0.14),
            false, i ~= math.max(1, 5 * -mirrorMult) and Color(120, 110, 250) or Color(50, 50, 50), "models/props_c17/metalladder001"
        ):setParent(rig)
        rig:setAngles(Angle(0, 0, 24 * i - 45))
    end
    rig:setAngles(Angle(0, -3 * mirrorMult, 0))
    SubHolo(
        Vector(0, 2.2 * mirrorMult, 68), Angle(-20, -10 * mirrorMult, 20 * mirrorMult),
        "models/holograms/cube.mdl", Vector(1.14, 0.1, 0.32),
        false, Color(120, 110, 250), "models/props_c17/metalladder001"
    ):setParent(rig)
    return rig
end

local body = {
    head = hologram.createPart(
        Holo(Rig(Vector(5, 0, 66), Angle())),
        Holo(SubHolo(Vector(2.3, 0, 68), Angle(), "models/combine_dropship_container.mdl", Vector(0.04, 0.06, 0.06))),
        Holo(SubHolo(Vector(-6.8, 0, 70), Angle(-20, 0, 0), "models/props_trainstation/trainstation_clock001.mdl", Vector(0.05, 0.05, 0.05), true, Color(255, 255, 0), "models/debug/debugwhite")),
        Holo(headBody(false)),
        Holo(headBody(true)),
        Holo(SubHolo(Vector(-2, 0, 67), Angle(-15, 0, 0), "models/holograms/rcube_thick.mdl", Vector(1.1, 0.3, 0.3), false, Color(120, 110, 255), "models/props_c17/metalladder001"))
    )
}


return body
