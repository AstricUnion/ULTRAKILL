---@name Player controller
---@author AstricUnion
---@shared



if SERVER then

    ---Cylinder-formed hitbox
    ---@param pos Vector Position of hitbox
    ---@param angle Angle Angle of hitbox
    ---@param size Vector Size of hitbox
    ---@param freeze boolean? Make hitbox freezed, default false
    ---@return Entity hitbox Hitbox entity
    local function createHitbox(pos, angle, size, freeze)
        local vertices = {}
        local polygons = 16
        for i=1,polygons do
            local ang = math.rad((360 / polygons) * i)
            local x = math.cos(ang) * size.x / 2
            local y = math.sin(ang) * size.y / 2
            table.insert(vertices, Vector(x, y, size.z))
            table.insert(vertices, Vector(x, y, 0))
        end
        local pr = prop.createCustom(
            pos,
            angle,
            {vertices},
            freeze
        )
        pr:setColor(Color(255, 255, 255, 0))
        return pr
    end

    ---@class PlayerController
    ---@field body Entity
    ---@field physobj PhysObj
    ---@field seat Vehicle
    ---@field driver Player
    ---@field camera Hologram
    ---@field cameraHeight number
    ---@field defCameraHeight number
    ---@field size Vector
    ---@field box [Vector, Vector]
    ---@field binds table<IN_KEY, table<function>>
    ---@field onTick table<string, function>
    ---@field onEnter table<string, function>
    ---@field onLeave table<string, function>
    ---@field isOnGroundCache boolean
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
        constraint.keepupright(body, Angle(), 0, 5000)
        local physobj = body:getPhysicsObject()
        physobj:setMass(1000)
        physobj:enableGravity(false)
        physobj:setMaterial("Player")
        physobj:addGameFlags(1024) -- no impact damage
        body:setCollisionGroup(COLLISION_GROUP.PLAYER)
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
                defCameraHeight = cameraHeight,
                driver = nil,
                size = size,
                box = { boxMin, boxMax },
                binds = { },
                onTick = { },
                onEnter = { },
                onLeave = { },
                isOnGroundCache = nil
            },
            PlayerController
        )
        obj:initHooks()
        return obj
    end

    ----- PHYSICS -----

    ---Is controller on ground. Only trace, without caching!
    ---Recomendally to not use this function, because it implements in tick
    ---@return boolean
    function PlayerController:isOnGroundTrace()
        local pos = self.body:getPos()
        local velocity = self:getVelocity()
        local res = trace.hull(
            pos,
            pos + Vector(0, 0, math.min(velocity.z / 73, 0) - 5),
            self.box[1],
            Vector(self.box[2].x, self.box[2].y, 0),
            {self.body},
            MASK.PLAYERSOLID,
            COLLISION_GROUP.PLAYER_MOVEMENT
        )
        self.isOnGroundCache = res.Hit
        return res.Hit
    end


    ---Is controller on ground
    ---@return boolean
    function PlayerController:isOnGround()
        return self.isOnGroundCache
    end


    ---Get velocity of controller
    ---@return Vector
    function PlayerController:getVelocity()
        return self.physobj:getVelocity()
    end

    ---Set velocity to controller
    ---@param vel Vector
    function PlayerController:setVelocity(vel)
        self.physobj:setVelocity(vel)
    end

    ---Add velocity to controller
    ---@param vel Vector
    function PlayerController:addVelocity(vel)
        self.physobj:addVelocity(vel)
    end


    ----- CALLBACKS -----
    
    ---Add bind to key
    ---@param key IN
    ---@param press? fun(self: PlayerController)
    ---@param release? fun(self: PlayerController)
    function PlayerController:addBind(key, press, release)
        self.binds[key] = { press, release }
    end

    
    ---Add callback to tick hook
    ---@param identifier string
    ---@param func fun(self: PlayerController, delta: number)
    function PlayerController:addOnTick(identifier, func)
        self.onTick[identifier] = func
    end


    ---Add callback to controller on enter
    ---@param identifier string
    ---@param func fun(self: PlayerController, ply: Player)
    function PlayerController:addOnEnter(identifier, func)
        self.onEnter[identifier] = func
    end


    ---Add callback to controller on enter
    ---@param identifier string
    ---@param func fun(self: PlayerController, ply: Player)
    function PlayerController:addOnLeave(identifier, func)
        self.onLeave[identifier] = func
    end


    ----- MISCELLANOUS -----

    ---Set camera height for controller
    ---@param height number nil to default
    function PlayerController:setCameraHeight(height)
        local resHeight = height or self.defCameraHeight
        net.start("PlayerControllerSetCameraHeight")
            net.writeInt(resHeight, 16)
        net.send(self.driver)
        self.cameraHeight = resHeight
    end


    ---Get eye trace
    ---@return TraceResult?
    function PlayerController:getEyeTrace()
        if !isValid(self.driver) then return end
        local pos = self.body:getPos() + Vector(0, 0, self.cameraHeight)
        local ang = self.driver:getEyeAngles()
        return trace.line(pos, pos + ang:getForward() * 16384, {self.body})
    end

    ----- HOOKS -----

    ---Initialize hooks for controller
    function PlayerController:initHooks()
        local id = "PlayerController" .. tostring(self.body:entIndex())
        local hooks = {
            "Tick",
            "PlayerEnteredVehicle",
            "PlayerLeaveVehicle",
            "KeyPress",
            "KeyRelease"
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


    ---Tick hook
    function PlayerController:Tick()
        self.physobj:setAngleVelocity(Vector())
        self.physobj:setAngles(Angle())
        local delta = game.getTickInterval()
        self:isOnGroundTrace()
        for _, func in pairs(self.onTick) do
            func(self, delta)
        end
    end


    ---PlayerEnteredVehicle hook
    function PlayerController:PlayerEnteredVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = ply
        enableHud(ply, true)
        ply:setViewEntity(self.camera)
        net.start("PlayerControllerActivate")
            net.writeEntity(self.body)
            net.writeInt(self.cameraHeight, 16)
        net.send(self.driver)
        for _, func in pairs(self.onEnter) do
            func(self, ply)
        end
    end

    ---PlayerLeaveVehicle hook
    function PlayerController:PlayerLeaveVehicle(ply, seat)
        if self.seat ~= seat then return end
        self.driver = nil
        ply:setViewEntity(nil)
        enableHud(ply, false)
        net.start("PlayerControllerDeactivate")
        net.send(self.driver)
        for _, func in pairs(self.onLeave) do
            func(self, ply)
        end
    end

    ---KeyPress hook
    function PlayerController:KeyPress(ply, key)
        if ply ~= self.driver then return end
        local bind = self.binds[key]
        if !bind then return end
        local func = bind[1]
        if func then func(self) end
    end

    ---KeyRelease hook
    function PlayerController:KeyRelease(ply, key)
        if ply ~= self.driver then return end
        local bind = self.binds[key]
        if !bind then return end
        local func = bind[2]
        if func then func(self) end
    end

    return PlayerController
else
    local PLAYER = player()
    local cameraHeight

    net.receive("PlayerControllerActivate", function()
        net.readEntity(function(ent)
            cameraHeight = net.readInt(16)
            hook.add("CalcView", "PlayerController", function(_, _, fov)
                local pos = ent:getPos() + Vector(0, 0, cameraHeight)
                local ang = PLAYER:getEyeAngles()
                local origin, angles, hookFov = hook.run("PlayerControllerCalcView", pos, ang)
                return {
                    origin = origin or pos,
                    angles = angles or ang,
                    fov = hookFov or fov
                }
            end)

            hook.run("PlayerControllerActivate", ent)
        end)
    end)

    net.receive("PlayerControllerDeactivate", function()
        hook.remove("CalcView", "PlayerController")
        cameraHeight = nil

        hook.run("PlayerControllerDeactivate")
    end)

    net.receive("PlayerControllerSetCameraHeight", function()
        cameraHeight = net.readInt(16)
    end)
end
