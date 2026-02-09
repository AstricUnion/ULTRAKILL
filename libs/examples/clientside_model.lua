---@name Model example
---@author AstricUnion
---@client

---@include astricunion/libs/holos.lua
---@module 'libs.holos'
local holos = require("astricunion/libs/holos.lua")
local Rig = holos.Rig
---@class Holo
local Holo = holos.Holo
local SubHolo = holos.SubHolo

---@class Model
---@module 'controller'
---@include ultrakill/libs/model.lua
local Model = require("ultrakill/libs/model.lua")


local model = Model:new(function()
        local body = {
            main = Rig(),
            bone1 = hologram.createPart(
                Rig(),
                Holo(SubHolo(nil, nil, "models/holograms/cube.mdl"))
            ),
            bone2 = hologram.createPart(
                Rig(Vector(0, 0, 10)),
                Holo(SubHolo(Vector(0, 0, 10), Angle(60, 0, 0), "models/holograms/right_prism.mdl"))
            )
        }
        body.bone1:setParent(body.main)
        body.bone2:setParent(body.bone1)
        return body
    end)
    :addAnimation("test", function()
    end)
