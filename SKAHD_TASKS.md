

## tasks for skahd when he starts:

- do floor textures 
- implement card-playing animation
- implement slash animations


## tasks for oli so skahd doesn't get blocked:
- ability-infrastructure (do we want buffering?)
- enemy-spawning infra
- gold-earning infra
- gold-spending (area-spend) infra
- cards wired up + working


card definition API:
```lua

g.defineCard("my_card", {
    cost = 1,
    getCostModifier = function(card)
        -- cost override
        if gold > g.getGold() then
            return -1
        end
        return 0
    end,

    init = function(card, ...)
        -- pass any args you want.
        self.state = 0
    end,

    drawCastPreview = function(card, player)
        -- called to serve as a "preview" for when casting abilities.
    end,
    drawCastPreviewPlayer = function(card, player)
        -- called to serve as a "preview" for when casting abilities.
        -- (called for every player)
    end,

    onCast = function(card)
        -- called ONCE only; no matter how many players
        g.addGold(5)
    end,
    onCastPlayer = function(card, player)
        -- called once for each "player" entity in the world.
        local x,y = g.getWorldMouse()
        local RANGE
        g.dashTowards(player, x,y, RANGE)
    end,
})

```


