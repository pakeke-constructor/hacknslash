local hud = {}

local MANA_BAR = { x = 20, y = 20, w = 300, h = 18 }

local CARD_SIZE = 64
local CARD_GAP = 8     -- gap between adjacent decks
local GROUP_GAP = 48   -- gap between attack/dash group and special
local BOTTOM_MARGIN = 20

local function drawManaBar(run)
    local b = MANA_BAR
    local frac = run.maxMana > 0 and (run.mana / run.maxMana) or 0
    lg.setColor(0, 0, 0, 0.5)
    lg.rectangle("fill", b.x, b.y, b.w, b.h)
    lg.setColor(0.3, 0.5, 1, 1)
    lg.rectangle("fill", b.x, b.y, b.w * frac, b.h)
    lg.setColor(1, 1, 1, 1)
    lg.rectangle("line", b.x, b.y, b.w, b.h)
end

-- Draws the first (top) card of a deck. g.drawCard centers on x,y.
local function drawDeckCard(deck, x, y)
    local card = deck.drawPile[1]
    if card then
        g.drawCard(card, x+CARD_SIZE/2, y+CARD_SIZE/2)
    end
end

function hud.draw()
    local run = g.getRun()
    if not run then return end
    local r = ui.getScreenRegion()
    local _main,botRegion = r:splitVertical(3,1)

    drawManaBar(run)

    local _, h = lg.getDimensions()
    local y = h - CARD_SIZE - BOTTOM_MARGIN

    local atk,dash,_,special = botRegion:splitHorizontal(1,1,4,1)

    -- attack, dash ...gap... special
    local x = MANA_BAR.x
    drawDeckCard(run.attackDeck, x, y)
    x = x + CARD_SIZE + CARD_GAP
    drawDeckCard(run.dashDeck, x, y)
    x = x + CARD_SIZE + GROUP_GAP
    drawDeckCard(run.specialDeck, x, y)
end

return hud
