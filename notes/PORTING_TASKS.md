# Porting Tasks (army-game → hack-n-slash)

Bring systems from `armygame/src/*` into `src/*`. Tiers ordered by priority.

## Tier 0 — dangling refs (already-ported code is BROKEN without these)
Current `g.lua`/`ECSWorld` reference these but they were never copied:
- `g.COLORS.POISON/BURN/DAMAGE/HEAL` — used [g.lua:512](src/g.lua#L512),[568](src/g.lua#L568). Src: armygame `g.lua:2566`.
- `consts.BURN_DPS` — used [g.lua:513](src/g.lua#L513).
- `drawWeapon(ent,x,y)` — called [g.lua:579](src/g.lua#L579). Src: armygame `g.lua:1745` (local fn).
- ~~`g.setCurrentECS` — called [ECSWorld.lua:176](src/ecs/ECSWorld.lua#L176).~~ DONE
- `ent.poisonAmount/burnTime/armor/frozenTime` — drawn in healthbar; need status_effects.

## Tier 1 — make it run + core swarm combat
- `g.COLORS` + status glue: `applyBurn/Poison/Frozen`, `addArmor`, `BURN_DPS` + `ecs/systems/status_effects.lua` (86)
- `drawWeapon` + `getEntityScale` wiring
- ~~ECS accessors: `g.setCurrentECS/getECS/tryGetECS`~~ DONE
- `ecs/systems/physics.lua` (124) + `g.setPos/getVel/knockback` — Box2D movement/collision/knockback (Physics component already exists)
- ~~`g.spawnEntity/defineEntity`~~ DONE (stripped of squad/scope/buffs/armor/ai/physics coupling; transformEntity skipped) + `entities/projectiles` (36) STILL TODO

## Tier 2 — game loop (upgrades / abilities)
- `ecs/systems/stats.lua` (99) + `g.defineStat/buffEntity`
- Scope system: `g.newScope/addCustomEffect` — per-entity buff/card-effect layering
- `ecs/systems/ai.lua` (266) + `attacking.lua` (339) — trim ranged/squad logic
- `g.explosion`

## Tier 3 — polish / meta loop
- `ecs/systems/shadows.lua` (25), `blood_system.lua` (50), `juice_system.lua` (313) + `juiceService.lua` — shake/hitstop/blood
- HUD: `hoverService` (91), `choicePopupService` (31), `rewardPopupService` (47), `gameoverPopupService` (68)
- `g.spawnParticle` + particles module
- `devcmd.lua` (188) — dev console

## Skip (army-game-specific)
- Squad system (`defineSquad/newSquad/addSquadToArmy`, `Squad.lua`) — we control 1 character; deck-of-cards replaces it
- Colored mana (`addMana`, R/G/B, `defineManaType`) — we use 1 Clash-Royale-style mana bar
- Map/graph scenes (`map_scene`, `MapGraph`, `nodes`, `shop_scene`) — open world, not node-graph
- Blessings & Commanders — overlap perks/characters but coupled to above; re-derive natively
