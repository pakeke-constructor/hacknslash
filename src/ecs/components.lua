

---@class ecs.components.Physics
---@field public shape "circle"|"rect"
---@field public radius number?
---@field public w number?
---@field public h number?
---@field public ox number
---@field public oy number
---@field public mass number
---@field public isStatic boolean?
---@field public damping number?
local physics = {
    shape = "circle",
    radius = 10,
    ox = 0,
    oy = 0,
    mass = 1,
    isStatic = false,
    damping = 10,
}


---@class ecs.components.Shadow
---@field public radius number?
---@field public opacity number?
local shadow = {
    radius = 3,
    opacity = 0.6,
}

---@class ecs.components.Area
---@field public type "rectangle"|"circle?
---@field public radius number?
---@field public width number?
---@field public height number?
local area = {
    type = "rectangle", -- "circle"/"rectangle"
    offsetX = 0,
    offsetY = 0,
    -- for circle
    radius = 10,
    -- for rectangle
    width = 10,
    height = 10,
    -- player stuff
    playerUpdate = function (ent, player, dt) end,
    playerCooldown = 0.3, -- cooldown for playerUpdate for EACH player
    playerCooldownTable = {},
}

---@class ecs.Components
---@field public color objects.Color?
---@field public alpha number? transparency
---@field public player boolean?
---@field public enemy boolean?
---@field public x number?
---@field public y number?
---@field public z number?
---@field public vx number?
---@field public vy number?
---@field public vz number?
---@field public _knockVx number?
---@field public _knockVy number?
---@field public rot number?
---@field public sx number?
---@field public sy number?
---@field public ox number?
---@field public oy number?
---@field public kx number?
---@field public ky number?
---@field public oyOverride number? oy (offsetY) defaults to 0.95, which is 95% of image, but you can override this here.
---@field public drawOrder number?
---@field public scale number?
---@field public faceDir integer?
---@field public team string?
---@field public image string?
---@field public health number?
---@field public buffs table<string, number>? flat stat buffs, keyed by stat name
---@field public maxHealth number?
---@field public baseMaxHealth number?
---@field public attackDamage number?
---@field public baseAttackDamage number?
---@field public damagePlayer boolean? deals attackDamage to players on physics-collision
---@field public invincibilityTime number? min seconds between taking enemy hits
---@field public _invincibleTimer number? remaining invincibility (counts down)
---@field public attackSpeed number?
---@field public baseAttackSpeed number?
---@field public autoAttack boolean?
---@field public _autoAttackCooldown number?
---@field public attackRange number?
---@field public baseAttackRange number?
---@field public healthRegen number?
---@field public baseHealthRegen number?
---@field public lifesteal number?
---@field public lifetime number?
---@field public homeTowardsEntity {target:ecs.Entity, onArrive:fun(self:ecs.Entity, targetEnt:ecs.Entity)}?
---@field public shadow ecs.components.Shadow?
---@field public _timeSinceDamaged number?
---@field public _timeSinceHealed number?
---@field public _damageLagAmount number?
---@field public onUpdate fun(ent:ecs.Entity, dt:number)?
---@field public onDraw fun(ent:ecs.Entity, x:number, y:number)?
---@field public physics ecs.components.Physics?
---@field public partitions string[]?
---@field public stackedGold number?
---@field public goldAmount number?
---@field public moveSpeed number?
---@field public area ecs.components.Area?
---@field public ___removed boolean?
---@field public ___dead boolean?
local ecs_Entity = {}
