local function isEntOnFloor(ent, floor)
    return g.AABB_isPointInRectangle(ent.x, ent.y, floor.x, floor.y, floor.width, floor.height)
end

g.defineEntity("payFloor", {
    -- gold = {cost=1},
    goldCost = 10,
    goldCostCooldown = {},
    -- unlock = fn

    width = 30,
    height = 30,

    onDraw = function (ent, x, y)
        lg.setColor(0.95, 0.95, 0.4, 0.3)
        lg.rectangle("fill", x, y, ent.width, ent.height)

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

            if isEntOnFloor(targ, ent) then
                if ent.goldCostCooldown[targ] <= 0 then
                    if g.trySpendGold(targ, 1) then
                        ent.goldCost = ent.goldCost - 1

                        ent.goldCostCooldown[targ] = 0.3
                    end
                end
            end

            ent.goldCostCooldown[targ] = ent.goldCostCooldown[targ] - dt
        end, 4)
    end
})
