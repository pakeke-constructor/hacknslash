

local enemies = {}

local DEFAULT_INVINCIBILITY = 0.5


function enemies:init()
    self.level = 0
end


-- enemy spawning system
function enemies:perSecondUpdate(dt)
    local r = g.getCameraRegion()
    local x,y = helper.pointOnRegionPerimeter(r:padRatio(-0.2), love.math.random())
    g.spawnEntity("basic_demon", x,y)
end


local function radius(ent)
    return (ent.physics and ent.physics.radius) or 10
end


---@param attacker ecs.Entity
---@param target ecs.Entity
local function tryDamage(attacker, target)
    if target._invincibleTimer then return end
    local dx, dy = target.x - attacker.x, target.y - attacker.y
    local r = radius(attacker) + radius(target)
    if dx * dx + dy * dy > r * r then return end -- not touching
    g.damageEntity(target, attacker.attackDamage, attacker)
    target._invincibleTimer = target.invincibilityTime or DEFAULT_INVINCIBILITY
end


-- tick player invincibility + deal touch damage from overlapping enemies.
-- Polled (not event-driven) so a player hugging an enemy keeps taking hits.
function enemies:postUpdate(dt)
    for _, ent in self.ecs:iterate("player") do
        if ent._invincibleTimer then
            ent._invincibleTimer = ent._invincibleTimer - dt
            if ent._invincibleTimer <= 0 then ent._invincibleTimer = nil end
        end

        if not ent._invincibleTimer then
            g.iteratePartition("enemy", ent.x, ent.y, function(enemy)
                if enemy.damagePlayer then tryDamage(enemy, ent) end
            end, radius(ent) + 32)
        end
    end
end




return enemies
