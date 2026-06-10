local slashSystem = {}

g.defineEntity("slash", {
    onDraw = function (ent, x, y)
        love.graphics.setColor(1, 1, 1)
        local r = math.atan2(ent.dy or 0, ent.dx or 0)
        g.drawImage("slash", x, y, r)
    end,
})

controlService.on("ATTACK", function ()
    local ecs = g.tryGetECS()
    if not ecs then return end

    for _, ent in ecs:iterate("player") do
        local x, y = g.screenToWorld(controlService.getPointer())
        local dx, dy = x-ent.x, y-ent.y
        g.playSlashAnimation(ent.x, ent.y, dx, dy)
    end
end)

return slashSystem