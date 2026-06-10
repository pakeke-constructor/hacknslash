local slashSystem = {}

local SPAN = math.pi * 0.7 -- total angular width of the slash arc

g.defineEntity("slash", {
    lifetime = 0.15,
    maxLifetime = 0.15,
    radius = 40, -- radius from the center to the edge of the slash
    reverse = false,
    onDraw = function (ent, x, y)
        local t  = helper.clamp(1 - ent.lifetime / ent.maxLifetime, 0, 1)
        if ent.reverse then t = 1-t end
        local a  = math.atan2(ent.dy or 0, ent.dx or 0)
        local r  = ent.radius
        local base = a - SPAN/2
        local a1 = base + helper.EASINGS.sineOut(t) * SPAN -- leading edge runs ahead
        local a0 = base + helper.EASINGS.sineIn(t)  * SPAN -- trailing edge lags behind
        local L  = r * 4         -- triangle legs long enough to fully cover the ring

        -- 1) write the triangle wedge into the stencil buffer
        lg.setColorMask(false)
        lg.setStencilState("replace", "always", 1)
        lg.polygon("fill",
            x, y,
            x + math.cos(a0)*L, y + math.sin(a0)*L,
            x + math.cos(a1)*L, y + math.sin(a1)*L)
        lg.setStencilState("keep", "greater", 0)
        lg.setColorMask(true)

        -- 2) draw the ring; only the wedge-masked arc shows
        lg.setColor(1, 1, 1, 1)
        lg.setLineWidth(r*3/4)
        lg.circle("line", x, y, r)

        -- 3) reset
        lg.setStencilState()
        lg.setLineWidth(1)
    end,
})

local isReverse = false
controlService.on("ATTACK", function ()
    local ecs = g.tryGetECS()
    if not ecs then return end

    for _, ent in ecs:iterate("player") do
        local x, y = g.screenToWorld(controlService.getPointer())
        local dx, dy = x-ent.x, y-ent.y
        local slash = g.playSlashAnimation(ent.x, ent.y, dx, dy, isReverse)
        isReverse = not isReverse
    end
end)

return slashSystem