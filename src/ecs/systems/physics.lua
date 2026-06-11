--[[
PHYSICS SYSTEM (love.physics):
==============================
Uses Box2D for collision resolution. Zero gravity (top-down).
AI sets ent.vx/vy -> we feed to Box2D -> Box2D resolves -> we read back positions.
ECSWorld skips manual vx/vy integration for entities with a physics component.

Runtime state lives on the system instance (fresh per ECSWorld):
  self.physicsWorld    -- love.World
  self.bodies          -- weak {[ent] = Body}
  self.fixtures        -- weak {[ent] = Fixture}

ent.physics is pure config and can be shared across entities.
]]

---@class ecs.PhysicsSystem: ecs.System
---@field physicsWorld love.World
---@field bodies table<ecs.Entity, love.Body>
---@field fixtures table<ecs.Entity, love.Fixture>
local physicsSys = {}

--- Create a weak-keyed table
local function weakTable()
    return setmetatable({}, {__mode = "k"})
end

function physicsSys:init()
    self.physicsWorld = love.physics.newWorld(0, 0, true)
    self.bodies = weakTable()
    self.fixtures = weakTable()

    -- emit onCollide for systems (eg enemy damage). Fired mid-step, so don't
    -- create/destroy bodies in handlers (entity removal is buffered = safe).
    self.physicsWorld:setCallbacks(function(fixA, fixB)
        local a, b = fixA:getBody():getUserData(), fixB:getBody():getUserData()
        if a and b then
            g.call("onCollide", a, b)
        end
    end,function()end,nil,nil)
end

---@param self ecs.PhysicsSystem
---@param ent ecs.Entity
local function initBody(self, ent)
    local p = assert(ent.physics)
    local bodyType = p.isStatic and "static" or "dynamic"
    local body = love.physics.newBody(self.physicsWorld, ent.x + (p.ox or 0), ent.y + (p.oy or 0), bodyType)
    body:setFixedRotation(true)
    body:setLinearDamping(p.damping or 10)
    body:setUserData(ent)

    ---@type love.Shape
    local shape
    if p.shape == "rect" then
        shape = love.physics.newRectangleShape(p.w, p.h)
    else
        shape = love.physics.newCircleShape(p.radius or 10)
    end

    local fixture = love.physics.newFixture(body, shape)
    fixture:setRestitution(0)
    fixture:setFriction(0)

    if not p.isStatic then
        body:setMass(p.mass or 1)
    end

    self.bodies[ent] = body
    self.fixtures[ent] = fixture
end

---@param self ecs.PhysicsSystem
---@param ent ecs.Entity
local function destroyBody(self, ent)
    local body = self.bodies[ent]
    if body and not body:isDestroyed() then
        body:destroy()
    end
    self.bodies[ent] = nil
    self.fixtures[ent] = nil
end

function physicsSys:preUpdate(dt)
    local world = self.ecs
    local bodies = self.bodies

    -- destroy bodies of removed/dead entities (iterate() no longer sees them)
    for ent in pairs(bodies) do
        if ent.___removed then
            destroyBody(self, ent)
        end
    end

    -- init new bodies, sync velocities
    for _, ent in world:iterate("physics") do
        if not bodies[ent] then
            initBody(self, ent)
        end
        if not ent.physics.isStatic then
            bodies[ent]:setLinearVelocity(g.getVel(ent))
        end
    end

    -- step Box2D
    self.physicsWorld:update(dt)

    -- read back positions
    for _, ent in world:iterate("physics") do
        if not ent.physics.isStatic then
            local body = bodies[ent]
            if body then
                local bx, by = body:getPosition()
                local p = assert(ent.physics)
                ent.x = bx - (p.ox or 0)
                ent.y = by - (p.oy or 0)
            end
        end
    end
end

function physicsSys:entityDeath(ent)
    destroyBody(self, ent)
end

return physicsSys
