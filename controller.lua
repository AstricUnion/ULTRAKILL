---@name Player controller
---@author AstricUnion
---@shared


local GRAVITY = 980

if SERVER then
    ---@class PlayerController
    ---@field body Entity
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
        local body = hologram.create(pos, Angle(), "models/editor/playerstart.mdl")
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
        local velocity = math.max(0, self:getVelocity().z)
        local res = trace.hull(
            pos + Vector(0, 0, 10),
            pos - Vector(0, 0, velocity + 5),
            self.box[1] / 3,
            Vector(self.box[2].x, self.box[2].y, 0) / 3,
            nil,
            MASK.PLAYERSOLID,
            COLLISION_GROUP.PLAYER_MOVEMENT
        )
        if res.Hit then
            self.body:setPos(res.HitPos)
        end
        return res.Hit
    end

    ---Collision of controller
    ---@return boolean, Vector?
    function PlayerController:getCollisions()
        local pos = self.body:getPos()
        local hitPos, hitNormal, hitFraction = trace.intersectRayWithOBB(
            pos + Vector(0, 0, 5),
            Vector(0, 0, 0),
            pos + Vector(0, 0, 5),
            Angle(),
            self.box[1],
            self.box[2]
        )
        return hitPos ~= nil, hitNormal
    end

    ---Get velocity of controller
    ---@return Vector
    function PlayerController:getVelocity()
        return self.body:getVelocity()
    end

    ---Set velocity to controller
    ---@param vel Vector
    function PlayerController:setVelocity(vel)
        self.body:setVelocity(vel - self.body:getVelocity())
        self:getCollisions()
    end

    ---Add velocity to controller
    ---@param vel Vector
    function PlayerController:addVelocity(vel)
        self:setVelocity(vel)
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
        if !self:isOnGround() then
            self:addVelocity(Vector(0, 0, -GRAVITY * game.getTickInterval()))
        else
            local speed = Vector()
            local axis = self:getControlAxis()
            if axis then
                local angs = self.driver:getEyeAngles():setP(0)
                speed = axis:getRotated(angs) * 500
            end
            self:setVelocity(speed)
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
