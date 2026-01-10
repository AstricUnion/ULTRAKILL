---@name Custom mesh
---@author AstricUnion
---@client


local CHIP = chip()

---@class CustomMesh
---@field url string
---@field defaultMaterial Material?
---@field materials table<string, Material>
---@field mesh table<string, Mesh>?
---@field holosToSet table<string, Hologram>
local CustomMesh = {}
CustomMesh.__index = CustomMesh


---Create new custom mesh info
---@param url string URL or path to OBJ file (from garrysmod/)
function CustomMesh:new(url)
    return setmetatable(
        {
            url = url,
            defaultMaterial = nil,
            materials = {},
            mesh = nil,
            holosToSet = {}
        },
        CustomMesh
    )
end


---Add new material to part
---@param names table Name of parts
---@param material Material Material to set
---@return CustomMesh
function CustomMesh:addMaterial(names, material)
    for _, name in ipairs(names) do
        self.materials[name] = material
    end
    return self
end


---Sets default material to parts
---Overrides with addMaterial
---@param material Material
---@return CustomMesh
function CustomMesh:setDefaultMaterial(material)
    self.defaultMaterial = material
    return self
end


---Initialize mesh
---@param callback? fun(self)
---@return CustomMesh
function CustomMesh:init(callback)
    http.get(self.url, function(obj)
        local loadmesh = coroutine.wrap(function()
            self.mesh = mesh.createFromObj(obj, true)
            return true
        end)
        local id = "LoadModel" .. self.url
        hook.add("Think", id, function()
            while CHIP:getQuotaAverage() < CHIP:getQuotaMax() / 2 do
                if loadmesh() then
                    if callback then callback(self) end
                    for name, holo in pairs(self.holosToSet) do
                        self:setTo(name, holo)
                    end
                    hook.remove("Think", id)
                    return
                end
            end
        end)
    end)
    return self
end


---Set mesh with material to holo
---@param name string Name of mesh part
---@param holo Hologram
function CustomMesh:setTo(name, holo)
    if !self:isInitialized() then
        self.holosToSet[name] = holo
        return
    end
    if !self.mesh[name] then
        return
    end
    holo:setMesh(self.mesh[name])
    local mat = self.materials[name]
    if mat then
        holo:setMeshMaterial(mat)
    elseif self.defaultMaterial then
        holo:setMeshMaterial(self.defaultMaterial)
    end
end


---Is custom mesh initialized and ready to be set?
---@return boolean
function CustomMesh:isInitialized()
    return self.mesh ~= nil
end


return CustomMesh
