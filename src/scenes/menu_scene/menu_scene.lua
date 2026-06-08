local sceneManager = require("src.scenes.sceneManager")

local menu_scene = {}

function menu_scene:init()
end

function menu_scene:enter()
end

function menu_scene:update(dt)
end

function menu_scene:keypressed(key)
    -- any key starts the run
    sceneManager.gotoScene("game_scene")
end

function menu_scene:mousepressed()
    sceneManager.gotoScene("game_scene")
end

function menu_scene:draw()
    local w, h = lg.getDimensions()
    lg.clear(0.05, 0.05, 0.07, 1)

    lg.setColor(1, 1, 1, 1)
    local title = "HACK N STACK"
    lg.printf(title, 0, h * 0.3, w, "center")

    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        lg.printf("PRESS ANY KEY", 0, h * 0.55, w, "center")
    end
end

return menu_scene
