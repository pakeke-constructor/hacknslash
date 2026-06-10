

local enemySpawning = {}


function enemySpawning:init()
    self.level = 0
end


function enemySpawning:perSecondUpdate(dt)
    local player
    local r = g.getCameraRegion()
    local x,y = helper.pointOnRegionPerimeter(r:padRatio(-0.2), love.math.random())
    g.spawnEntity("basic_demon", x,y)
end


function enemySpawning:postDraw()
    local r = g.getCameraRegion()
    -- lg.rectangle("line", r:padRatio(0.2):get())
end


return enemySpawning

