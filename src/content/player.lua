

local PLAYER_SPEED = 50
local function doPlayerMovement(ent, dt)
    local dx,dy = controlService.getMoveAxis()
    ent.vx = dx*PLAYER_SPEED
    ent.vy = dy*PLAYER_SPEED
end



g.defineEntity("player", {
    player = true,

    onUpdate = function (ent, dt)
        doPlayerMovement(ent,dt)
    end
})

