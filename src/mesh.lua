---@name Custom mesh
---@author AstricUnion
---@shared


if CLIENT then
    local CHIP = chip()

    ---@class CustomMesh
    ---@field url string
    ---@field defaultMaterial Material?
    ---@field materials table<string, Material>
    ---@field mesh table<string, Mesh>?
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
                mesh = nil
            },
            CustomMesh
        )
    end


    ---Add new material to part
    ---@param name string
    ---@param material Material
    ---@return CustomMesh
    function CustomMesh:addMaterial(name, material)
        self.materials[name] = material
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
                self.model = mesh.createFromObj(obj, true)
                return true
            end)
            hook.add("Think", "LoadModel",function()
                while CHIP:getQuotaAverage() < CHIP:getQuotaMax() / 2 do
                    if loadmesh() then
                        if callback then callback(self) end
                        hook.remove("Think","LoadModel")
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
        if !self.model[name] then
            local available = table.concat(
                table.getKeys(self.model),
                ", "
            )
            throw("No such part: " .. name .. ". Available parts: " .. available)
            return
        end
        holo:setMesh(self.model[name])
        local mat = self.materials[name]
        if mat then
            holo:setMeshMaterial(mat)
        elseif self.defaultMaterial then
            holo:setMeshMaterial(self.defaultMaterial)
        end
    end
end
