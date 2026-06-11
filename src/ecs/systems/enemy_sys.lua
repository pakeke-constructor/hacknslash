

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


-- tick down player invincibility
function enemies:postUpdate(dt)
    for _, ent in self.ecs:iterate("player") do
        if ent._invincibleTimer then
            ent._invincibleTimer = ent._invincibleTimer - dt
            if ent._invincibleTimer <= 0 then ent._invincibleTimer = nil end
        end
    end
end


---@param attacker ecs.Entity
---@param target ecs.Entity
local function tryDamage(attacker, target)
    if not attacker.damagePlayer then return end
    if not target.player or target._invincibleTimer then return end
    g.damageEntity(target, attacker.attackDamage, attacker)
    target._invincibleTimer = target.invincibilityTime or DEFAULT_INVINCIBILITY
end


-- damagePlayer enemies hurt players on touch (uses "player" partition tag)
function enemies:onCollide(a, b)
    print(a,b)
    tryDamage(a, b)
    tryDamage(b, a)
end




return enemies
