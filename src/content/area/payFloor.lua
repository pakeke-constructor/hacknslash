g.defineEntity("payFloor", {
    goldCost = 10,
    goldCostCooldown = {},
    -- unlock = fn

    area = {
        type = "rectangle",
        width = 40,
        height = 40,
        playerCooldown = 0.3,
        playerUpdate = function (ent, player, dt)
            if ent.goldCost <= 0 then
                return
            end
            if g.trySpendGold(player, 1) then
                ent.goldCost = ent.goldCost - 1
                return true
            end

            return false
        end,
    },

    onDraw = function (ent, x, y)
        lg.setColor(0.95, 0.95, 0.4, 0.3)
        local w, h = ent.area.width, ent.area.height
        lg.rectangle("fill", x-w/2, y-h/2, w, h)

        lg.setColor(1, 1, 0.7)
        richtext.printRichContainedNoWrap("$" .. ent.goldCost .. "/" .. "10", g.getSmallFont(16), x-10, y-25, 20, 20)
    end,
})
