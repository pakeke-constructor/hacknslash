



-- Spawned loose when the player EARNS money, or homed to a spendable when the
-- player SPENDS money. See gold_sys for both flows.
g.defineEntity("goldcoin", {
    image = "gold_coin",
    goldAmount = 1,
})



--[[

spendable: 

money can be "sent" to this entity.
When enough money is sent, this entity has like a `onPurchase` callback or whatever.



]]


g.defineEntity("payZone", {
    init = function(ent, x,y, ...)
        -- todo, pass stuff here?
    end,
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
            g.trySpendGold(player, ent)

            return false
        end,
    },

    goldCost = 10,
    goldSpendComplete = function(ent)
        print("SPENT: ", ent)
    end,

    onDraw = function (ent, x, y)
        lg.setColor(0.95, 0.95, 0.4, 0.3)
        local area = ent.playerDetectArea
        local w, h = area.width, area.height
        lg.rectangle("fill", x-w/2, y-h/2, w, h)

        lg.setColor(1, 1, 0.7)
        richtext.printRichContainedNoWrap("$" .. ent.goldCost, g.getSmallFont(16), x-10, y-25, 20, 20)
    end,
})
