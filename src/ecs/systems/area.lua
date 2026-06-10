local areaSystem = {}

function areaSystem:init()

end

function areaSystem:preUpdate(dt)
    local ecs = g.tryGetECS()
    if not ecs then return end
    
    for _, ent in ecs:iterate("area") do
        if ent.area.playerUpdate == nil then
            goto continue
        end
        ent.area.playerCooldownTable = ent.area.playerCooldownTable or {}
        local max = math.ceil(math.max(ent.area.height or 0, ent.area.width or 0))+1
        ecs:iteratePartition("player", ent.x, ent.y, function (targ)
            local ct = ent.area.playerCooldownTable
            ct[targ] = ct[targ] or 0
            local cooldown = ct[targ]
            
            if helper.AABB_isPointInEnt(targ.x, targ.y, ent) then
                ct[targ] = ct[targ] - dt
                if cooldown <= 0 then
                    if ent.area.playerUpdate(ent, targ, dt) then
                        ct[targ] = ct[targ] + ent.area.playerCooldown
                    end
                end
            end
        end, max)

        ::continue::
    end
end

return areaSystem