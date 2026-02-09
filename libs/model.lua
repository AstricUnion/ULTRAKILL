---@name Clientside model
---@author AstricUnion
---@client

---@alias animation fun(model: table, payload: table?): Tween
---@alias bones table<string, Hologram>
---@alias create fun(): bones 


----- Model class -----

---@class ModelData
---@field create create
---@field animations table<number, animation>
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
---@param id number
---@param func animation
function ModelData:addAnimation(id, func)
    self.animations[id] = func
end


----- Model -----
---@class Model
---@field model bones
---@field data ModelData
---@field currentSequence number?
---@field sequenceTween Tween? Tween to control animation
---@field sequenceStartedAt number? When sequence started. Relative to CurTime
---@field currentSequenceDuration number? Sequence duration
local Model = {}
Model.__index = Model


---[CLIENT] Create new model
---@param data ModelData
---@return Model
function Model:new(data)
    local model = ModelData.create()
    return setmetatable({
        model = model,
        data = data
    }, Model)
end


---[CLIENT] Remove model
function Model:remove()
    for _, holo in pairs(self.model) do
        holo:remove()
    end
    if self.sequenceTween then
        self.sequenceTween:remove()
    end
    setmetatable(self, nil)
end


---[CLIENT] Move model
---@param pos Vector
function Model:setPos(pos)
    self.model.origin:setPos(pos)
end


---[CLIENT] Set angles to model
---@param ang Angle
function Model:setAngles(ang)
    self.model.origin:setAngles(ang)
end


---[CLIENT] Play sequence
---@param id number Sequence ID
---@param payload table? Payload to animation (e. g. to procedural)
function Model:setSequence(id, payload)
    local sequence = self.data.animations[id]
    if !sequence then return end
    local tw = sequence(self.model, payload)
    self.currentSequence = id
    local dur = 0
    for _, params in ipairs(tw.parameters) do
        local max = 0
        for _, param in ipairs(params) do
            if max >= param.duration then goto cont end
            max = param.duration
            ::cont::
        end
        dur = dur + max
    end
    self.currentSequenceDuration = dur
    self.sequenceStartedAt = CurTime()
    self.sequenceTween = tw
end


---[CLIENT] Get current sequence
---@return number? id
function Model:getSequence()
    return self.currentSequence
end


---[CLIENT] Get current sequence duration
---@return number?
function Model:sequenceDuration()
    return self.currentSequenceDuration
end


---[CLIENT] Is sequence finished
function Model:isSequenceFinished()
    return CurTime() - self.currentSequenceDuration >= self.sequenceStartedAt
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


---[CLIENT] Create new model.
---@param id string
---@return Model?
function models.create(id)
    local data = models.registered[id]
    if !data then return end
    return Model:new(data)
end



return models
