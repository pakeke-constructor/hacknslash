g.defineEntity("payFloor", {
    -- gold = {cost=1},
    goldCost = 10,
    goldCostCooldown = {},
    -- unlock = fn

    onDraw = function (ent, x, y)
        lg.setColor(0.95, 0.95, 0.4, 0.3)
        lg.circle("fill", x, y, 20)
        -- lg.print("hi", x, y)

        lg.setColor(1, 1, 0.7)
        richtext.printRichContainedNoWrap("$" .. ent.goldCost .. "/" .. "10", g.getSmallFont(16), x-10, y-25, 20, 20)
    end,

    onUpdate = function (ent, dt)
        -- doPlayerMovement(ent, dt)
        local ecs = g.tryGetECS()
        if not ecs then return end

        if ent.goldCost <= 0 then
            return
        end

        ecs:iteratePartition("holdCoin", ent.x, ent.y, function (targ)
            ent.goldCostCooldown[targ] = ent.goldCostCooldown[targ] or 0
            if ent.goldCostCooldown[targ] <= 0 then
                if g.trySpendGold(targ, 1) then
                    ent.goldCost = ent.goldCost - 1

                    ent.goldCostCooldown[targ] = 0.3
                end
            end

            ent.goldCostCooldown[targ] = ent.goldCostCooldown[targ] - dt
        end, 1)
    end
})
