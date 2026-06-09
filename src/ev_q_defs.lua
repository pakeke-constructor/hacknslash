local g = require("src.g")
local reducers = require("src.modules.reducers")

local MUL = reducers.MULTIPLY


-- Core frame flow (dispatched by ECSWorld)
g.defineEvent("preUpdate")
g.defineEvent("postUpdate")
g.defineEvent("preDraw")
g.defineEvent("postDraw")


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
