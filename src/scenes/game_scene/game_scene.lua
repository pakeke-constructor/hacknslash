local sceneManager = require("src.scenes.sceneManager")

local game_scene = {}

function game_scene:init()
end

function game_scene:enter()
end

function game_scene:update(dt)
end

function game_scene:keypressed(key)
    if key == "escape" then
        sceneManager.gotoScene("menu_scene")
    end
end

function game_scene:draw()
    local w, h = lg.getDimensions()
    lg.clear(0.02, 0.03, 0.04, 1)

    lg.setColor(1, 1, 1, 1)
    lg.printf("GAME SCENE", 0, h * 0.5, w, "center")
end

return game_scene
