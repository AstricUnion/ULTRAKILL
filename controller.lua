---@name Player controller
---@author AstricUnion
---@shared


local GRAVITY = 980

if SERVER then
    ---Cube-formed hitbox. Modified from hitbox lib: https://raw.githubusercontent.com/AstricUnion/Libs/refs/heads/main/hitbox.lua
    ---@param pos Vector Position of hitbox
    ---@param angle Angle Angle of hitbox
    ---@param size Vector Size of hitbox
    ---@param freeze boolean? Make hitbox freezed, default false
    ---@return Entity hitbox Hitbox entity
    local function createHitbox(pos, angle, size, freeze)
        local actualSize = size / 2
        local pr = prop.createCustom(pos, angle,
            {{
                Vector(-actualSize.x, -actualSize.y, 0), Vector(actualSize.x, -actualSize.y, 0),
                Vector(actualSize.x, actualSize.y, 0), Vector(-actualSize.x, actualSize.y, 0),
                Vector(-actualSize.x, -actualSize.y, size.z), Vector(actualSize.x, -actualSize.y, size.z),
                Vector(actualSize.x, actualSize.y, size.z), Vector(-actualSize.x, actualSize.y, size.z),
            }},
            freeze
        )
        return pr
    end

    ---@class PlayerController
    ---@field body Entity
    ---@field physobj PhysObj
    ---@field seat Vehicle
    ---@field camera Hologram
    ---@field cameraHeight number
    ---@field size Vector
    ---@field box table[Vector, Vector]
    local PlayerController = {}
    PlayerController.__index = PlayerController

    ---Initialize new PlayerController - body, with physics like player
    ---@param pos Vector
    ---@param seat Vehicle
    ---@param cameraHeight number
    ---@param size Vector
    ---@return PlayerController?
    function PlayerController:new(pos, seat, cameraHeight, size)
        local body = createHitbox(pos, Angle(), size, false)
        local physobj = body:getPhysicsObject()
        physobj:setMass(1000)
        physobj:setMaterial("Player")
        physobj:enableGravity(false)
        constraint.keepupright(body, Angle(), 0, 10000)

        local camera = hologram.create(pos + Vector(0, 0, cameraHeight), Angle(), "models/editor/camera.mdl")
        if !camera then return end
        camera:setNoDraw(true)
        camera:setParent(body)

        local halfSize = size / 2
        local boxMin = Vector(-halfSize.x, -halfSize.y, 0)
        local boxMax = Vector(halfSize.x, halfSize.y, size.z)
        local obj = setmetatable(
            {
                body = body,
                physobj = physobj,
                seat = seat,
                camera = camera,
                cameraHeight = cameraHeight,
                driver = nil,
                size = size,
                box = { boxMin, boxMax }
            },
            PlayerController
        )
        obj:initHooks()
        return obj
    end

    ----- PHYSICS -----

    ---Is controller on ground
    ---@return boolean
    function PlayerController:isOnGround()
        local pos = self.body:getPos()
        return trace.hull(
            pos,
            pos - Vector(0, 0, 5),
            self.box[1],
            self.box[2],
            {self.body}
        ).Hit
    end


    ----- HOOKS -----
  
    ---Initialize hooks for controller
    function PlayerController:initHooks()
        local id = "PlayerController" .. tostring(self.body:entIndex())
        local hooks = {
            "Think",
            "PlayerEnteredVehicle",
            "PlayerLeaveVehicle",
            -- "KeyPress",
            -- "KeyRelease"
        }
        for _, name in ipairs(hooks) do
            hook.add(name, id, function(...) self[name](self, ...) end)
        end
    end


    ---Get vector of controls (GMod binded movement)
    function PlayerController:getControlAxis()
        if !self.driver then return end
        local getAxis = function(negative, positive)
            return (self.driver:keyDown(positive) and 1 or 0) - (self.driver:keyDown(negative) and 1 or 0)
        end
        return Vector(
            getAxis(IN_KEY.BACK, IN_KEY.FORWARD),
            getAxis(IN_KEY.MOVERIGHT, IN_KEY.MOVELEFT),
            0
        )
    end


    ---Think hook
    function PlayerController:Think()
        self.physobj:setAngleVelocity(Vector())
        self.physobj:setAngles(Angle())
        if !self:isOnGround() then
            self.physobj:addVelocity(Vector(0, 0, -GRAVITY * game.getTickInterval()))
        else
            local speed = Vector()
            local axis = self:getControlAxis()
            if axis then
                local angs = self.driver:getEyeAngles():setP(0)
                speed = axis:getRotated(angs) * 500
            end
            self.physobj:setVelocity(speed)
        end
    end


    ---PlayerEnteredVehicle hook
    function PlayerController:PlayerEnteredVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = ply
        enableHud(ply, true)
        ply:setViewEntity(self.camera)

        net.start("PlayerControllerCamera")

            net.writeEntity(self.body)
            net.writeInt(self.cameraHeight, 16)

        net.send(self.driver)
    end

    ---PlayerLeaveVehicle hook
    function PlayerController:PlayerLeaveVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = nil
        ply:setViewEntity(nil)
        enableHud(ply, false)
    end

    local CHIPPOS = chip():getPos()
    local seat = prop.createSeat(CHIPPOS, Angle(), "models/nova/chair_plastic01.mdl", true)
    local controller = PlayerController:new(CHIPPOS + Vector(50, 0, 0), seat, 80, Vector(24, 24, 80))
else
    local PLAYER = player()
    net.receive("PlayerControllerCamera", function()
        net.readEntity(function(ent)
            local cameraHeight = net.readInt(16)
            hook.add("CalcView", "", function()
                return {
                    origin = ent:getPos() + Vector(0, 0, cameraHeight),
                    angles = PLAYER:getEyeAngles(),
                }
            end)
        end)
    end)
end
