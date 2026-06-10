
local objects = require("src.modules.objects.objects")

---@class g.Run: objects.Class
---@field character string
---@field difficulty integer
---@field level integer
---@field xp number
---@field money number
local Run = objects.Class("g:Run")


---@class g.Deck: objects.Class
---@field deckType string
---@field drawPile objects.Array<g.Card>
---@field discardPile objects.Array<g.Card>
local Deck = objects.Class("g:Deck")

---@param typ string
function Deck:init(typ)
    --todo; store cards here
    self.deckType = typ
    self.drawPile = objects.Array()
    self.discardPile = objects.Array()
end

function Deck:reshuffle()
    local buf = objects.Array()
    for _, c in ipairs(self.drawPile) do
        buf:add(c)
    end
    for _, c in ipairs(self.discardPile) do
        buf:add(c)
    end
    self.discardPile:clear()
    helper.shuffle(buf)
    self.drawPile = buf
end

---@param self g.Deck
local function forcePlayCard(self)
    local card = self.drawPile:pop()
    self.discardPile:add(card)
    card:cast()
    if self.drawPile:size() <= 0 then
        self:reshuffle()
    end
end

function Deck:update(dt)
end

function Deck:tryPlayCard()
    -- play card animation n stuff.
    -- activate ability
    if self.drawPile:size() <= 0 then return end -- no cards in deck!
    local mana = self.drawPile:peek():getCost()
    local ret = false
    if g.trySpendMana(mana) then
        forcePlayCard(self)
        ret = true
    end
    if self.drawPile:size() <= 0 then
        self:reshuffle()
    end
    return ret
end



function Run:init()
    self.character = nil -- string
    self.difficulty = 0
    self.level = 1
    self.xp = 0
    self.mana = 0
    self.maxMana = 10

    self.dashDeck = Deck("dash")
    self.attackDeck = Deck("attack")
    self.specialDeck = Deck("special")
end


function Run:update(dt)
    self.mana = math.min(self.mana + consts.MANA_REGEN_PER_SECOND*dt, self.maxMana)
end


function Run:getXpRequirement()
    return 100 -- TODO. implement properly.
end


---@return {character: string?, difficulty: integer, level: integer, xp: number, money: number}
function Run:serialize()
    return {
        character = self.character,
        difficulty = self.difficulty,
        level = self.level,
        xp = self.xp,
        maxMana = self.maxMana,
    }
end


---@param data {character: string?, difficulty: integer?, level: integer?, xp: number?, maxMana: number?}?
---@return g.Run
function Run.deserialize(data)
    local run = Run()
    if not data then
        return run
    end
    run.character = data.character or run.character
    run.difficulty = data.difficulty or run.difficulty
    run.level = data.level or run.level
    run.xp = data.xp or run.xp
    run.maxMana = data.maxMana or run.maxMana
    return run
end

return Run
