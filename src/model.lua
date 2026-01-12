---@name Mesh
---@author AstricUnion
---@client
---@include ultrakill/libs/mesh.lua

---@class CustomMesh
local CustomMesh = require("ultrakill/libs/mesh.lua")

---Holos to apply model. Index is name, value is holo
local GITHUB_URL = "https://raw.githubusercontent.com/AstricUnion/ULTRAKILL/refs/heads/fullremaster/"


-- Textures --
local mainTexture = material.create("VertexLitGeneric")
mainTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/main.png")

local wingTexture = material.create("VertexLitGeneric")
wingTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/wing.png")

local revolverTexture = material.create("VertexLitGeneric")
revolverTexture:setTextureURL("$basetexture", GITHUB_URL .. "textures/weapons/revolverDiff_9.png")
--------------

local mesh = CustomMesh:new(GITHUB_URL .. "models/v1.obj")
    :setDefaultMaterial(mainTexture)
    :addMaterial(
        {
            "WingRight1", "WingRight2", "WingRight3", "WingRight4",
            "WingLeft1", "WingLeft2", "WingLeft3", "WingLeft4",
        },
        wingTexture
    )
    :addMaterial({"Revolver", "RevolverCylinder"}, revolverTexture)
    :init()


return mesh
