

---@class g.areaSystem: ecs.System
local areaSystem = {}



function areaSystem:init()
end



function areaSystem:preUpdate(dt)
    local ecs = g.tryGetECS()
    if not ecs then return end
    
    for _, ent in ecs:iterate("playerDetectArea") do
        local area = assert(ent.playerDetectArea)
        if area.playerUpdate == nil then
            goto continue
        end
        area.playerCooldownTable = area.playerCooldownTable or {}
        local max = math.ceil(math.max(area.height or 0, area.width or 0))+1
        ecs:iteratePartition("player", ent.x, ent.y, function (targ)
            local ct = area.playerCooldownTable
            ct[targ] = ct[targ] or 0
            local cooldown = ct[targ]
            
            if helper.AABB_isPointInEnt(targ.x, targ.y, ent) then
                ct[targ] = ct[targ] - dt
                if cooldown <= 0 then
                    if area.playerUpdate(ent, targ, dt) then
                        ct[targ] = ct[targ] + area.playerCooldown
                    end
                end
            end
        end, max)

        ::continue::
    end
end

return areaSystem