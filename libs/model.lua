---@name Clientside model
---@author AstricUnion
---@client

---@alias animation fun(model: table, payload: table?): Tween
---@alias create fun(pos: Vector, ang: Angle): table<string, Hologram>
---@alias bones table<string, Hologram>


----- Model class -----

---@class ModelData
---@field create create
---@field animations table<string, animation>
local ModelData = {}
ModelData.__index = ModelData


---[CLIENT] Create new model data
---@param func create Creation func. Should return table with holograms and bones
---@return ModelData
function ModelData:new(func)
    return setmetatable({
        create = func,
        animations = {}
    }, ModelData)
end


---[CLIENT] Adds new animation
---@param id string
---@param func animation
function ModelData:addAnimation(id, func)
    self.animations[id] = func
end


----- Model -----
---@class Model
---@field model bones
---@field currentSequence string?
---@field sequenceTween Tween?
---@field data ModelData
local Model = {}
Model.__index = Model


---[CLIENT] Create new model
---@param pos Vector
---@param ang Angle
---@param data ModelData
---@return Model
function Model:new(pos, ang, data)
    local model = ModelData.create(pos, ang)
    return setmetatable({
        model = model,
        data = data
    }, Model)
end


----- Models class -----

---Class to manipulate models
---@class models
---@field registered table<string, ModelData>
local models = {}
models.registered = {}


---[CLIENT] Register new model.
---Returns model data, so you can edit data (e. g. add animation)
---@param id string
---@param func create
---@return ModelData
function models.register(id, func)
    local data = ModelData:new(func)
    models.registered[id] = data
    return data
end


---[CLIENT] Load and create new model.
---@param pos Vector
---@param ang Angle
---@param id string
---@return Model?
function models.create(pos, ang, id)
    local data = models.registered[id]
    if !data then return end
    return Model:new(pos, ang, data)
end



return models
