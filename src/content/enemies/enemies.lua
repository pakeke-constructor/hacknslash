
local DEMON_SPEED = 50

local function closestPlayer(ent)
    local players = g.getECS():getPlayers()
    local best, bestDist
    for i = 1, #players do
        local p = players[i]
        local dx, dy = p.x - ent.x, p.y - ent.y
        local d = dx * dx + dy * dy
        if not bestDist or d < bestDist then
            best, bestDist = p, d
        end
    end
    return best
end


g.defineEntity("basic_demon", {
    image = "demon",

    partitions = {"enemy"},

    moveSpeed = DEMON_SPEED,
    maxHealth = 40,

    physics = { shape = "circle", radius = 6, mass = 1 },

    onUpdate = function (ent, dt)
        -- TODO:
        --  extract demon-AI into it's own system
        local target = closestPlayer(ent)
        if not target then
            ent.vx, ent.vy = 0, 0
            return
        end
        local dx, dy = target.x - ent.x, target.y - ent.y
        local len = math.sqrt(dx * dx + dy * dy)
        if len > 0 then
            ent.vx = dx / len * ent.moveSpeed
            ent.vy = dy / len * ent.moveSpeed
        end

        -- TODO: extract this faceDir stuff into it's own system
        if dx ~= 0 then ent.faceDir = dx > 0 and 1 or -1 end
    end
})

