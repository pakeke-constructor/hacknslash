


---@class g.exampleSystem: ecs.System
local autoAttacks = {}



function autoAttacks:postUpdate(dt)
    for _, ent in self.ecs:iterate("player") do
        if not ent.autoAttack then goto continue end

        ent._autoAttackCooldown = (ent._autoAttackCooldown or 0) - dt
        if ent._autoAttackCooldown > 0 then goto continue end

        -- pick the in-range enemy closest to the mouse
        local mx, my = g.getMouseInWorldSpace()
        local closest, closestDist
        g.iteratePartition("enemy", ent.x, ent.y, function(targ)
            local dx, dy = targ.x - mx, targ.y - my
            local d = dx * dx + dy * dy
            if not closestDist or d < closestDist then
                closest, closestDist = targ, d
            end
        end, ent.attackRange)

        if closest then
            g.damageEntity(closest, ent.attackDamage, ent)
            ent._autoAttackCooldown = ent.attackSpeed
        end

        ::continue::
    end
end




return autoAttacks
