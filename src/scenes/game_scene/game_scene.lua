local sceneManager = require("src.scenes.sceneManager")
local ECSWorld = require("src.ecs.ECSWorld")
local hud = require("src.ui.hud")
local Camera = require("src.scenes.game_scene.camera")

local game_scene = {}

local CAMERA_SCALE = 2

-- Ground tiles are scattered in a square grid centered on the world origin.
local GROUND_SPACING = 20
local GROUND_GRID_RADIUS = 8 -- spawns (2r+1)^2 ground_tex entities


local GROUND_COLOR = objects.Color("FF58443B")

local GAME_OVER_TEXT = "{o}{blink}"..loc("GAME OVER!")



function game_scene:init()
end

function game_scene:enter()
    self.world = ECSWorld()
    g.setCurrentECS(self.world)

    -- Register system handlers now so entitySpawned fires for entities we spawn
    -- here in enter() (otherwise stats/health never get set until next frame).
    g.pollHandlers()

    self.camera = Camera(CAMERA_SCALE)

    -- Lay down a bunch of ground textures across the play field.
    for gx = -GROUND_GRID_RADIUS, GROUND_GRID_RADIUS do
        for gy = -GROUND_GRID_RADIUS, GROUND_GRID_RADIUS do
            local dx,dy = love.math.random(-50,50), love.math.random(-50,50)
            g.spawnEntity("ground_tex", gx * GROUND_SPACING + dx, gy * GROUND_SPACING + dy)
        end
    end

    g.spawnEntity("payZone", 100, 0)

    -- The player starts at the center of the world.
    self.player = g.spawnEntity("basic_champion", 0, 0)
end

function game_scene:leave()
    g.setRun(nil)
    self.world = nil
    self.player = nil
    self.camera = nil
end

-- Re-registered every frame by g.pollHandlers so ECS systems can hook events.
function game_scene:pollHandlers()
    self.world:addSystemHandlers()
end

function game_scene:update(dt)
    g.pollHandlers()
    local run = assert(g.getRun())
    run:update(dt)
    self.world:update(dt)

    if self.player then
        self.camera.x, self.camera.y = self.player.x, self.player.y
    end
    self.camera:update()

    local C = controlService.CONTROLS
    if controlService.wasJustPressed(C.ATTACK) then
        run.attackDeck:tryPlayCard()
    elseif controlService.wasJustPressed(C.DASH) then
        run.dashDeck:tryPlayCard()
    elseif controlService.wasJustPressed(C.SPECIAL) then
        run.specialDeck:tryPlayCard()
    end
end

function game_scene:keypressed(key)
    if key == "escape" then
        sceneManager.gotoScene("menu_scene")
    end
end

function game_scene:draw()
    lg.clear(GROUND_COLOR)

    lg.push()
    lg.applyTransform(self.camera:getTransform())
    self.world:draw()
    lg.pop()

    ui.startUI()
    -- HUD draws in screen space, outside the camera transform.
    hud.draw()

    if #self.world:getPlayers() == 0 then
        lg.setColor(0, 0, 0, 0.7)
        lg.rectangle("fill", ui.getFullScreenRegion():get())
        lg.setColor(1, 1, 1, 1)
        richtext.printRichContained(GAME_OVER_TEXT, g.getBigFont(48),
            ui.getScreenRegion():padRatio(0.5):get())
    end
    ui.endUI()
end

return game_scene
