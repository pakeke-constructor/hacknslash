
local objects = require("src.modules.objects.objects")

---@class g.Run: objects.Class
---@field character string
---@field difficulty integer
---@field level integer
---@field xp number
---@field money number
local Run = objects.Class("g:Run")


function Run:init()
    self.character = nil -- string
    self.difficulty = 0
    self.level = 1
    self.xp = 0
    self.money = 0
end


function Run:update(dt)
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
        money = self.money,
    }
end

---@param data {character: string?, difficulty: integer?, level: integer?, xp: number?, money: number?}?
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
    run.money = data.money or run.money
    return run
end

return Run
