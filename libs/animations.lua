---@name V1 animations
---@author AstricUnion
---@include https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/tweens.lua as tweens
---@module 'astricunion.libs.tweens'
require("tweens")


if SERVER then
  
    ---@class Animations
    ---@field model table<string, table | Hologram>
    ---@field animations table<string, fun(self: Animations, model: table, payload: table?)>
    ---@field currentTween Tween?
    ---@field currentAnimation string
    local Animations = {}
    Animations.__index = Animations

    ---Create new animations object for V1 model
    ---@param model table<string, table | Hologram>
    ---@return Animations
    function Animations:new(model)
        return setmetatable(
            {
                model = model,
                animations = {},
                currentTween = nil,
                currentAnimation = nil
            },
            Animations
        )
    end


    ---Add new animation to model
    ---@param id string Animation identifier to play it
    ---@param callback fun(self: Animations, model: table, payload: table?): Tween?
    function Animations:add(id, callback)
        self.animations[id] = callback
    end

    ---Play animation
    ---@param id string
    ---@param payload? table Payload to animation
    function Animations:play(id, payload)
        if self.currentTween then
            self.currentTween:remove()
            self.currentTween = nil
        end
        self.currentAnimation = id
        self.currentTween = self.animations[id](self, self.model, payload)
    end


    ---Get current animation ID
    ---@return string id
    function Animations:get()
        return self.currentAnimation
    end

    return Animations

end


