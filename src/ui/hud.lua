local hud = {}

local CARD_SIZE = 64
local CARD_GAP = 8     -- gap between adjacent decks
local GROUP_GAP = 48   -- gap between attack/dash group and special

local function drawManaBar(run, region)
    local x, y, w, h = region:get()
    local frac = run.maxMana > 0 and (run.mana / run.maxMana) or 0
    lg.setColor(0, 0, 0, 0.5)
    lg.rectangle("fill", x, y, w, h)
    lg.setColor(0.3, 0.5, 1, 1)
    lg.rectangle("fill", x, y, w, h*frac)
    lg.setColor(1, 1, 1, 1)
    lg.rectangle("line", x, y, w, h)
end

-- Draws the first (top) card of a deck, centered in its slot region.
local function drawDeckCard(deck, slot)
    local card = deck.drawPile[1]
    if card then
        g.drawCard(card, slot:getCenter())
    end
end

function hud.draw()
    local run = g.getRun()
    if not run then return end

    local r = ui.getScreenRegion()
    local main, botRegion = r:splitVertical(3, 1)

    local _, manaBar = main:splitHorizontal(9,1)
    drawManaBar(run, manaBar:padRatio(0.2))

    -- attack, dash ...gap... special  (gaps are discarded regions)
    local atk, _g1, dash, _g2, special =
        botRegion:splitHorizontalExact(CARD_SIZE, CARD_GAP, CARD_SIZE, GROUP_GAP, CARD_SIZE)

    drawDeckCard(run.attackDeck, atk)
    drawDeckCard(run.dashDeck, dash)
    drawDeckCard(run.specialDeck, special)
end

return hud
