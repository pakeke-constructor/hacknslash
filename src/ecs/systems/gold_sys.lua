

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

function goldSystem:postUpdate()
    local numIters = 0
    for _,coinEnt in self.ecs:iterate("goldAmount") do
        
        
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
