local goldSystem = {}

-- EXAMPLE USAGE..?
-- controlService.on("ATTACK", function ()
--     local ecs = g.tryGetECS()
--     if not ecs then return end

--     for _, ent in ecs:iterate("gold") do
--         g.addGold(ent, 1)
--     end
-- end)

-- controlService.on("SPECIAL", function ()
--     local ecs = g.tryGetECS()
--     if not ecs then return end

--     for _, ent in ecs:iterate("gold") do
--         g.trySpendGold(ent, 2)
--     end
-- end)

function goldSystem:init()

end

-- function goldSystem:preUpdate()
--     local ecs = g.tryGetECS()
--     if not ecs then return end
    
--     for _, ent in ecs:iterate("gold") do
        
--     end
-- end

function goldSystem:drawEntity(ent, x, y)
    if ent.gold then
        for i=1, ent.gold do
            g.drawImage("gold_coin", x, y - 20 - i*5, 0, 0.5, 0.5)
        end
    end
end

return goldSystem