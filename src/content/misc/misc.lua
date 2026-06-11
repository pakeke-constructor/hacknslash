



-- spawned when player EARNS money
g.defineEntity("goldcoin_earn", {
    image = "gold_coin",
    goldAmount = 1,
})

-- spawned when player SPENDS money
g.defineEntity("goldcoin_spend", {
    image = "gold_coin",
    goldAmount = 1,
})



--[[

spendable: 

money can be "sent" to this entity.
When enough money is sent, this entity has like a `onPurchase` callback or whatever.



]]



g.defineEntity("payFloor", {
    init = function(ent, x,y, ...)
        -- todo, pass stuff here?
    end,
    goldCost = 10,
    -- unlock = fn

    playerDetectArea = {
        type = "rectangle",
        width = 40,
        height = 40,
        playerCooldown = 0.016,
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
        local area = ent.playerDetectArea
        local w, h = area.width, area.height
        lg.rectangle("fill", x-w/2, y-h/2, w, h)

        lg.setColor(1, 1, 0.7)
        richtext.printRichContainedNoWrap("$" .. ent.goldCost .. "/" .. "10", g.getSmallFont(16), x-10, y-25, 20, 20)
    end,
})
