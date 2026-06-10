local sceneManager = require("src.scenes.sceneManager")
local ECSWorld = require("src.ecs.ECSWorld")
local hud = require("src.ui.hud")

local game_scene = {}

local CAMERA_SCALE = 2

-- Ground tiles are scattered in a square grid centered on the world origin.
local GROUND_SPACING = 20
local GROUND_GRID_RADIUS = 8 -- spawns (2r+1)^2 ground_tex entities

function game_scene:init()
end

function game_scene:enter()
    self.world = ECSWorld()
    g.setCurrentECS(self.world)

    -- Lay down a bunch of ground textures across the play field.
    for gx = -GROUND_GRID_RADIUS, GROUND_GRID_RADIUS do
        for gy = -GROUND_GRID_RADIUS, GROUND_GRID_RADIUS do
            local dx,dy = love.math.random(-50,50), love.math.random(-50,50)
            g.spawnEntity("ground_tex", gx * GROUND_SPACING + dx, gy * GROUND_SPACING + dy)
        end
    end

    -- The player starts at the center of the world.
    self.player = g.spawnEntity("player", 0, 0)
end

function game_scene:leave()
    g.setRun(nil)
    self.world = nil
    self.player = nil
end

-- Re-registered every frame by g.pollHandlers so ECS systems can hook events.
function game_scene:pollHandlers()
    self.world:addSystemHandlers()
end

function game_scene:update(dt)
    g.pollHandlers()
    self.world:update(dt)
end

function game_scene:keypressed(key)
    if key == "escape" then
        sceneManager.gotoScene("menu_scene")
    end
end

--- Camera transform: centers the player on screen at CAMERA_SCALE zoom.
---@return love.Transform
function game_scene:getCameraTransform()
    local w, h = lg.getDimensions()
    local px, py = 0, 0
    if self.player then
        px, py = self.player.x, self.player.y
    end
    local t = love.math.newTransform()
    t:translate(w / 2, h / 2)
    t:scale(CAMERA_SCALE, CAMERA_SCALE)
    t:translate(-px, -py)
    return t
end

function game_scene:draw()
    lg.clear(0.02, 0.03, 0.04, 1)

    lg.push()
    lg.applyTransform(self:getCameraTransform())
    self.world:draw()
    lg.pop()

    -- HUD draws in screen space, outside the camera transform.
    hud.draw()
end

return game_scene
