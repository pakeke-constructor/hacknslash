

--[[
STATS SYSTEM:
Recomputes player stats every frame from base values + question-bus modifiers.
Single source of truth; no stale caches. Only players have stats.

  stat = (base + modifier + buff) * multiplier

See g.defineStat. To buff: g.buffEntity(ent, stat, amount), or answer
getXxxModifier / getXxxMultiplier via handlers/scopes.
]]

---@param ent ecs.Entity
---@param stat g.Stat
local function recomputeStat(ent, stat)
    local base = ent[stat.baseName]
    if not base then return end
    local buff = (ent.buffs and ent.buffs[stat.name]) or 0
    local val = (base + g.ask(stat.modQ, ent) + buff) * g.ask(stat.mulQ, ent)
    ent[stat.name] = val
end

---@param ent ecs.Entity
local function recomputeAll(ent)
    for _, stat in ipairs(g.getStatList()) do
        recomputeStat(ent, stat)
    end
end


---@class g.systems.stats: ecs.System
local stats = {}

---@param ent ecs.Entity
function stats:entitySpawned(ent)
    if ent.player then
        recomputeAll(ent)
    end
    if ent.maxHealth then
        ent.health = ent.maxHealth
    end
end


function stats:preUpdate(dt)
    for _, ent in self.ecs:iterate("player") do
        recomputeAll(ent)
    end
end


function stats:perSecondUpdate()
    for _, ent in self.ecs:iterate("player") do
        if ent.healthRegen and ent.health and ent.health < ent.maxHealth then
            -- dont call `g.healEntity` here coz we dont wanna trigger event every time.
            ent.health = math.min(ent.health + ent.healthRegen, ent.maxHealth)
        end
    end
end



return stats
