---@name Model example
---@author AstricUnion
---@server
---@include astricunion/libs/holos.lua
---@include ultrakill/libs/model.lua
---@include ultrakill/libs/newtweens.lua

---@module 'libs.holos'
local holos = require("astricunion/libs/holos.lua")
local Rig = holos.Rig
---@class Holo
local Holo = holos.Holo
local SubHolo = holos.SubHolo

---@module 'libs.model'
---@class models
local models = require("ultrakill/libs/model.lua")

---@module 'libs.newtweens'
---@class tweens
local tweens = require("ultrakill/libs/newtweens.lua")
---@class Param
local P = tweens.Param
local PR = tweens.PROPERTY

local data = models.register(
    "prism_on_cube",
    function()
        local body = {
            origin = Rig(),
            bone1 = SubHolo(nil, nil, "models/holograms/cube.mdl"),
            bone2 = hologram.createPart(
                Holo(Rig(Vector(0, 0, 10))),
                Holo(SubHolo(Vector(0, 0, 10), Angle(60, 0, 0), "models/holograms/right_prism.mdl"))
            )
        }
        body.bone1:setParent(body.main)
        body.bone2:setParent(body.bone1)
        return body
    end
)
data:addAnimation(0, function()
    return tweens.new()
end)
data:addAnimation(1, function(model)
    return tweens.new(
        P:new(model.bone1, 0, 0.3, PR.LOCALANGLES, Angle(), Angle(90, 0, 0), math.easeInCubic),
        P:new(model.bone2, 0, 0.3, PR.LOCALANGLES, Angle(), Angle(70, 0, 0), math.easeInCubic),
        P:new(model.bone1, 0.3, 0.6, PR.LOCALANGLES, Angle(90, 0, 0), Angle(), math.easeOutCubic),
        P:new(model.bone2, 0.3, 0.6, PR.LOCALANGLES, Angle(70, 0, 0), Angle(), math.easeOutCubic)
    )
end)

local model = models.create("prism_on_cube")
if !model then return end
model:setPos(chip():getPos())
model:setSequence(0)

timer.simple(1, function()
    model:setSequence(1)
end)
