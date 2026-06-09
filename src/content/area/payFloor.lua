g.defineEntity("payFloor", {
    goldCost = 10,
    goldCostCooldown = {},
    -- unlock = fn

    area = {
        type = "rectangle",
        width = 40,
        height = 40,
    },

    onDraw = function (ent, x, y)
        lg.setColor(0.95, 0.95, 0.4, 0.3)
        local w, h = ent.area.width, ent.area.height
        lg.rectangle("fill", x-w/2, y-h/2, w, h)

        lg.setColor(1, 1, 0.7)
        richtext.printRichContainedNoWrap("$" .. ent.goldCost .. "/" .. "10", g.getSmallFont(16), x-10, y-25, 20, 20)
    end,

    onUpdate = function (ent, dt)
        -- maybe abstract some of these
        local ecs = g.tryGetECS()
        if not ecs then return end

        if ent.goldCost <= 0 then
            return
        end

        ecs:iteratePartition("holdCoin", ent.x, ent.y, function (targ)
            ent.goldCostCooldown[targ] = ent.goldCostCooldown[targ] or 0
            if g.AABB_isPointInEnt(targ.x, targ.y, ent) then
                if ent.goldCostCooldown[targ] <= 0 then
                    if g.trySpendGold(targ, 1) then
                        ent.goldCost = ent.goldCost - 1

                        ent.goldCostCooldown[targ] = 0.3
                    end
                end
            end

            ent.goldCostCooldown[targ] = ent.goldCostCooldown[targ] - dt
        end, 10)
    end
})
