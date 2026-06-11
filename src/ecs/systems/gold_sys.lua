

---@class g.systems.goldSystem: ecs.System
local goldSystem = {}


--------------------------------------------------------------------------------
-- Gold API (this system is the single owner of all gold logic)
--------------------------------------------------------------------------------

local DEFAULT_SPREAD_DISTANCE = 10

--- Spawns `amount` loose coins that home to nearby players (see postUpdate).
---@param x number
---@param y number
---@param amount number
---@param spreadDistance number?
function g.spawnGold(x, y, amount, spreadDistance)
    spreadDistance = spreadDistance or DEFAULT_SPREAD_DISTANCE
    for i = 1, amount do
        local dx = love.math.random(-spreadDistance, spreadDistance)
        local dy = love.math.random(-spreadDistance, spreadDistance)
        g.spawnEntity("goldcoin", x + dx, y + dy)
    end
end

--- Adds gold to an entity's stack.
---@param ent ecs.Entity
---@param amount number
function g.addGold(ent, amount)
    ent.stackedGold = (ent.stackedGold or 0) + amount
end

--- Drips 1 gold from `ent` toward `targetEnt` (a spendable, e.g. payZone).
--- Gold leaves the stack now; targetEnt.goldCost ticks down as each coin lands.
---@param ent ecs.Entity
---@param targetEnt ecs.Entity
function g.trySpendGold(ent, targetEnt)
    if (ent.stackedGold or 0) <= 0 then return end
    if (targetEnt.goldCost or 0) <= 0 then return end
    if not targetEnt.goldSpendComplete then return end

    ent.stackedGold = ent.stackedGold - 1

    local coin = g.spawnEntity("goldcoin", ent.x, ent.y)
    coin.homeTowardsEntity = {
        target = targetEnt,
        onArrive = function(self, targEnt)
            targEnt.goldCost = targEnt.goldCost - 1
            if targEnt.goldCost <= 0 then
                targEnt:goldSpendComplete()
            end
            g.killEntity(self)
        end,
    }
end


--------------------------------------------------------------------------------
-- System: loose coins home to the nearest player and get collected
--------------------------------------------------------------------------------

local MAX_ITERS_PER_FRAME = 20
local PICKUP_RANGE = 80
local COIN_SPEED = 350


---@param coin ecs.Entity
---@param player ecs.Entity
local function collect(coin, player)
    g.addGold(player, coin.goldAmount)
    coin:getWorld():removeEntity(coin)
end


function goldSystem:postUpdate()
    local players = self.ecs:getPlayers()
    if #players == 0 then return end

    local numIters = 0
    for _, coinEnt in self.ecs:iterate("goldAmount") do
        if coinEnt.homeTowardsEntity then goto continue end

        numIters = numIters + 1
        if numIters > MAX_ITERS_PER_FRAME then break end

        -- find closest player
        local closest, closestDist
        for _, p in ipairs(players) do
            local dx, dy = p.x - coinEnt.x, p.y - coinEnt.y
            local d = dx * dx + dy * dy
            if not closestDist or d < closestDist then
                closest, closestDist = p, d
            end
        end

        if closest and closestDist <= PICKUP_RANGE * PICKUP_RANGE then
            coinEnt.moveSpeed = COIN_SPEED
            coinEnt.homeTowardsEntity = { target = closest, onArrive = collect, oy = -20 }
        end

        ::continue::
    end
end


---@param ent ecs.Entity
---@param x number
---@param y number
function goldSystem:drawEntity(ent, x, y)
    lg.setColor(1, 1, 1)
    if ent.stackedGold then
        for i = 1, ent.stackedGold do
            g.drawImage("gold_coin", x, y - 20 - i * 5, 0, 1, 1)
        end
    end
end


return goldSystem
