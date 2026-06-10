local sceneManager = require("src.scenes.sceneManager")
local Run = require("src.Run")

local menu_scene = {}

function menu_scene:init()
end

function menu_scene:enter()
end

function menu_scene:update(dt)
end


local function startRun()
    -- TODO: load from saved data instead when continuing a run.
    local run = Run()

    -- TODO: temp test cards. Remove once decks are built from run state.
    run.attackDeck.drawPile:add(g.newCardInstance("basic_slash"))
    run.attackDeck.drawPile:add(g.newCardInstance("basic_shield"))
    run.dashDeck.drawPile:add(g.newCardInstance("heroic_dash"))
    run.dashDeck.drawPile:add(g.newCardInstance("wing_dash"))
    run.specialDeck.drawPile:add(g.newCardInstance("radial_slash"))

    g.setRun(run)

    sceneManager.gotoScene("game_scene")
end

function menu_scene:keypressed(key)
    -- any key starts the run
    startRun()
end

function menu_scene:mousepressed()
    startRun()
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
