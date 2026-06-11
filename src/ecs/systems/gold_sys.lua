

---@class g.systems.goldSystem: ecs.System
local goldSystem = {}


--[[
With spend/collect sequence, changes we need to make:

remove g.* gold funcs, move to area-system thing
add g.spawnGold(x,y, amount) that spawns a bunch of gold-coins to collect
make goldcoins move towards player(s) automatically, and be collected automatically
]]




function goldSystem:init()

end

-- function goldSystem:preUpdate()
--     local ecs = g.tryGetECS()
--     if not ecs then return end
    
--     for _, ent in ecs:iterate("gold") do
        
--     end
-- end



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
            coinEnt.homeTowardsEntity = { target = closest, onArrive = collect }
        end

        ::continue::
    end
end




---@param ent ecs.Entity
---@param x number
---@param y number
function goldSystem:drawEntity(ent, x, y)
    if ent.stackedGold then
        for i=1, ent.stackedGold do
            g.drawImage("gold_coin", x, y - 20 - i*5, 0, 0.5, 0.5)
        end
    end
end

return goldSystem
