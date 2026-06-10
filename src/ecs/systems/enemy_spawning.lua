

local enemySpawning = {}


function enemySpawning:init()
    self.level = 0
end


function enemySpawning:perSecondUpdate(dt)
    local player
    -- g.spawnEntity("basic_demon")
end


function enemySpawning:postDraw()
    local r = g.getCameraRegion()
    -- lg.rectangle("line", r:padRatio(0.2):get())
end


return enemySpawning

