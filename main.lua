
local love = require("love")
--io.stdout:setvbuf("line")

_G.lg = love.graphics
_G.table.clear = require("table.clear")


lg.setDefaultFilter("nearest", "nearest")
lg.setLineStyle("rough")



-- relative-require
do
local stack = {""}
local oldRequire = require
local function stackRequire(path)
    table.insert(stack, path)
    local result = oldRequire(path)
    table.remove(stack)
    return result
end


--[[
we *MUST* overwrite `require` here,
or else the stack will become malformed.
]]
function _G.require(path)
    if (path:sub(1,1) == ".") then
        -- its a relative-require!
        local lastPath = stack[#stack]
        if lastPath:find("%.") then -- then its a valid path1
            local subpath = lastPath:gsub('%.[^%.]+$', '')
            return stackRequire(subpath .. path)
        else
            -- we are in root-folder; remove the dot and require
            return stackRequire(path:sub(2))
        end
    else
        return stackRequire(path)
    end
end

end



local _loadtime = true
function _G.isLoadTime()
    return _loadtime
end



_G.lg = love.graphics

_G.utf8 = require("utf8")
_G.json = require("lib.json")


---@type g.consts
_G.consts = require("src.consts")

_G.log = require("src.modules.log")
_G.typecheck = require("src.modules.typecheck.typecheck")
_G.objects = require("src.modules.objects.objects")
_G.helper = require("src.modules.helper.helper")
_G.richtext = require("src.modules.richtext.exports")
_G.localization = require("src.modules.localization")
_G.gsman = require("src.modules.gsman.gsman")
_G.loc = _G.localization.localize
_G.interp = _G.localization.newInterpolator
_G.iml = require("lib.iml.iml")
_G.Kirigami = require("lib.kirigami")
_G.ui = require("src.ui.ui")

_G.analytics = require("src.modules.analytics.analytics")
_G.agentbridge = require("src.modules.agentbridge.agentbridge")
_G.vignette = require("src.modules.vignette.vignette")
_G.textPopupService = require("src.modules.textPopupService")

_G.g = require("src.g")


require("src.ev_q_defs")


local subpixel = require("src.modules.subpixel")

local sceneManager = require("src.scenes.sceneManager")


local bgm = require("src.sound.bgm")
local sfx = require("src.sound.sfx")




function love.load()
    assert(love.filesystem.createDirectory("saves"))
    vignette.setStrength(0.8)
    analytics.init(nil)
    if consts.DEV_MODE then
        love.keyboard.setTextInput(true)
    end
    g.loadImagesFrom("assets")
    g.requireFolder("src/content")
    sceneManager.loadScenes()
    sceneManager.gotoScene("menu_scene")
    for _, a in ipairs(arg or {}) do
        local port = a:match("^%-%-devport=(%d+)$")
        if port then agentbridge.start(tonumber(port)); break end
    end
    _loadtime = false
end

function love.update(dt)
    agentbridge.update()
    sfx.update()
    local BGM_VOL=1-- todo, pass proper value here
    bgm.update(dt, BGM_VOL)
    textPopupService.update(dt)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.update then
        sc:update(dt)
    end
end

function love.quit()
    agentbridge.stop()
end

function love.draw()
    lg.setShader(subpixel.shader)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.draw then
        sc:draw()
    end
    textPopupService.draw()
    vignette.draw()
    if consts.DEV_MODE then
        local _, sceneName = sceneManager.getCurrentScene()
        local fps = love.timer.getFPS()
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.push()
        love.graphics.scale(2)
        love.graphics.printf((sceneName or "") .. "  FPS: " .. fps, 0, 2, love.graphics.getWidth() / 2 - 4, "right")
        love.graphics.pop()
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function love.keypressed(key, scancode, isrep)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keypressed then
        sc:keypressed(key, scancode, isrep)
    end
end

function love.keyreleased(key, scancode)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.keyreleased then
        sc:keyreleased(key, scancode)
    end
end

function love.mousepressed(mx, my, button, istouch, presses)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousepressed then
        sc:mousepressed(mx, my, button, istouch, presses)
    end
end

function love.mousereleased(mx, my, button, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousereleased then
        sc:mousereleased(mx, my, button, istouch)
    end
end

function love.mousemoved(mx, my, dx, dy, istouch)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.mousemoved then
        sc:mousemoved(mx, my, dx, dy, istouch)
    end
end

function love.wheelmoved(dx, dy)
    local sc = sceneManager.getCurrentScene()
    if sc and sc.wheelmoved then
        sc:wheelmoved(dx, dy)
    end
end

function love.resize(w, h)
    vignette.resize()
    local sc = sceneManager.getCurrentScene()
    if sc and sc.resize then
        sc:resize(w, h)
    end
end
