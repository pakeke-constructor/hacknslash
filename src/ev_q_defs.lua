local g = require("src.g")
local reducers = require("src.modules.reducers")

local MUL = reducers.MULTIPLY


-- Core frame flow (dispatched by ECSWorld)
g.defineEvent("preUpdate")
g.defineEvent("postUpdate")
g.defineEvent("perSecondUpdate") -- (dt) called once per second
g.defineEvent("preDraw")
g.defineEvent("postDraw")


-- Entity lifecycle
g.defineEvent("entitySpawned")     -- (ent)

-- Physics
g.defineEvent("onCollide")  -- (entA, entB) both orders NOT emitted; check both

g.defineEvent("drawEntity")  -- (ent, x, y)


-- Entity combat
g.defineEvent("entityDamaged")   -- (target, damage)
g.defineEvent("entityHealed") -- (ent, finalHeal, healerEnt)
g.defineEvent("entityDeath")  -- (ent, killer)
g.defineEvent("onHitDamage")  -- attacker first arg: (attacker, damage, target)
g.defineEvent("onHitHeal")    -- healer first arg: (healer, finalHeal, target)
g.defineEvent("onKill")       -- killer first arg: (killer, victim)


-- Questions
g.defineQuestion("getEntityScale", MUL, 1)
g.defineQuestion("getDamageTakenMultiplier", MUL, 1)


-- Stats (only players have these). Each generates getXxxModifier/getXxxMultiplier questions.
g.defineStat("maxHealth", "baseMaxHealth", { displayName = "Health" })
g.defineStat("attackDamage", "baseAttackDamage", { displayName = "Attack Damage" })
g.defineStat("attackSpeed", "baseAttackSpeed", { displayName = "Attack Speed" })
g.defineStat("attackRange", "baseAttackRange", { displayName = "Attack Range" })
g.defineStat("healthRegen", "baseHealthRegen", { displayName = "Health Regen" })
