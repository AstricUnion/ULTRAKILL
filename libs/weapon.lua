---@name AUW (AstricUnion Weapon)
---@author AstricUnion
---@shared


---@class AUW
local AUW = {}


---Create empty AUW object
---@return AUW
function AUW:new()
    return setmetatable({
        ViewModel = nil,
        WorldModel
    }, AUW)
end


setmetatable(AUW, { __call = AUW.new, __index = AUW })

return AUW
