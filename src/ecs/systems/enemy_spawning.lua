

local enemySpawning = {}


function enemySpawning:init()
    self.level = 0
end


function enemySpawning:perSecondUpdate(dt)
    local player
    g.spawnEntity("basic_demon")
end



return enemySpawning

