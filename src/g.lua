

---@class g.g
local g = {}

local lg = love.graphics

local Entity = require("src.ecs.Entity")

local AutoAtlas = require("lib.AutoAtlas.AutoAtlas")

local atlas = AutoAtlas(2048, 2048)

local nameToQuad = {}

local richtext = require("src.modules.richtext.exports")

local consts = require("src.consts")
local sfx = require("src.sound.sfx")
local bgm = require("src.sound.bgm")

local sceneManager = require("src.scenes.sceneManager")
local textPopupService = require("src.modules.textPopupService")
local table_clear = require("table.clear")



--------------------------------------------------------------------------------
-- Atlas / image drawing
--------------------------------------------------------------------------------

---@return love.Texture
function g.getAtlas()
    return atlas:getTexture()
end

---@param imageName string
function g.getImageQuad(imageName)
    local quad = nameToQuad[imageName]
    if not quad then
        error("Invalid quad: " .. tostring(imageName))
    end
    return quad
end

---@param imageName string
---@return number w
---@return number h
function g.getImageSize(imageName)
    local quad = g.getImageQuad(imageName)
    local _, _, w, h = quad:getViewport()
    return w, h
end

---@param imageName any
---@return boolean
function g.isImage(imageName)
    return (nameToQuad[imageName] and true) or false
end

---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param kx number?
---@param ky number?
function g.drawImage(imageName, x, y, r, sx, sy, kx, ky)
    return g.drawImageOffset(imageName, x, y, r, sx, sy, 0.5, 0.5, kx, ky)
end

---@param imageName string|love.Quad
---@param x number
---@param y number
---@param r number?
---@param sx number?
---@param sy number?
---@param ox number?
---@param oy number?
---@param kx number?
---@param ky number?
function g.drawImageOffset(imageName, x, y, r, sx, sy, ox, oy, kx, ky)
    local quad
    if type(imageName) == "string" then
        quad = g.getImageQuad(imageName)
    else
        if not (imageName.typeOf and imageName:typeOf("Quad")) then
            error("Expected quad, got: " .. type(imageName) .. " " .. tostring(imageName))
        end
        quad = imageName
    end
    local _, _, w, h = quad:getViewport()
    atlas:draw(quad, x, y, r, sx, sy, (ox or 0.5) * w, (oy or 0.5) * h, kx, ky)
end

---@param imageName string
---@param x number
---@param y number
---@param w number
---@param h number
---@param rot number?
function g.drawImageContained(imageName, x, y, w, h, rot)
    local quad = g.getImageQuad(imageName)
    local _, _, qw, qh = quad:getViewport()
    local scaleX = w / qw
    local scaleY = h / qh
    local scale = math.min(scaleX, scaleY)
    local scaledW = qw * scale
    local scaledH = qh * scale
    local centerX = x + (w - scaledW) / 2
    local centerY = y + (h - scaledH) / 2
    atlas:draw(quad, centerX + scaledW / 2, centerY + scaledH / 2, rot or 0, scale, scale, qw / 2, qh / 2)
end




local PALETTE = {
    {197, 48, 61},
    {89, 71, 29},
    {79, 45, 93},
    {54, 199, 222},
    {200, 82, 164},
    {29, 58, 81},
    {17, 18, 17},
    {99, 99, 99},
    {46, 68, 209},
    {166, 84, 27},
    {95, 57, 39},
    {29, 27, 14},
    {205, 133, 59},
    {8, 8, 8},
    {255, 255, 255},
    {54, 30, 25},
    {20, 14, 18},
    {39, 39, 71},
    {39, 55, 24},
    {188, 227, 233},
    {72, 72, 72},
    {0, 0, 0},
    {53, 125, 210},
    {35, 100, 73},
    {241, 241, 30},
    {124, 200, 42},
    {100, 106, 53},
    {77, 140, 33},
    {44, 44, 44},
    {140, 159, 169},
    {124, 34, 34},
    {225, 185, 123}
}
for i, c in ipairs(PALETTE) do
    PALETTE[i] = objects.Color.fromByteRGBA(c[1], c[2], c[3])
end

---Snap a color to the nearest palette entry.
---Uses 4th-power channel distance to deeply penalize large per-channel differences.
---Preserves the input alpha.
---@param r number red [0..1]
---@param gg number green [0..1]
---@param b number blue [0..1]
---@param a number? alpha [0..1] (default 1)
---@overload fun(color:objects.Color):objects.Color
---@return objects.Color
function g.snapToPalette(r, gg, b, a)
    if type(r) == "table" then
        r, gg, b, a = r[1], r[2], r[3], r[4]
    end
    a = a or 1
    local best, bestDist = nil, math.huge
    for _, c in ipairs(PALETTE) do
        local rbar = (r + c.r) * 0.5
        local dr, dg, db = r - c.r, gg - c.g, b - c.b
        -- redmean: cheap perceptual RGB distance
        local dist = (2 + rbar)*dr*dr + 4*dg*dg + (3 - rbar)*db*db
        if dist < bestDist then
            bestDist = dist
            best = c
        end
    end
    assert(best, "?")
    return best:clone():setRGBA(nil, nil, nil, a)
end








--------------------------------------------------------------------------------
-- Directory walking / image loading
--------------------------------------------------------------------------------



---@param path string
function g.requireFolder(path)
    local results = {}
    g.walkDirectory(path:gsub("%.", "/"), function(pth)
        if pth:sub(-4, -1) == ".lua" then
            pth = pth:sub(1, -5)
            results[pth] = require(pth:gsub("%/", "."))
        end
    end)
    return results
end


---@param path string
---@param func fun(path: string)
function g.walkDirectory(path, func)
    local info = love.filesystem.getInfo(path)
    if not info then return end

    if info.type == "file" then
        func(path)
    elseif info.type == "directory" then
        local dirItems = love.filesystem.getDirectoryItems(path)
        for _, pth in ipairs(dirItems) do
            g.walkDirectory(path .. "/" .. pth, func)
        end
    end
end

local validImgExtensions = {
    [".png"] = true,
    [".jpg"] = true,
}

local function loadImage(path)
    local ext = path:sub(-4):lower()
    if validImgExtensions[ext] then
        local name = path:match("([^/]+)%.%w+$")
        local quad = atlas:add(love.image.newImageData(path))
        if nameToQuad[name] then
            error("Duplicate image: " .. name)
        end
        nameToQuad[name] = quad
        richtext.defineImage(name, atlas:getTexture(), quad)
    end
end

---@param path string
function g.loadImagesFrom(path)
    g.walkDirectory(path, loadImage)
end


-- Define 1x1 white image
do
    -- Add padding around to prevent bleeding
    local id = love.image.newImageData(3, 3, "rgba8")
    id:mapPixel(function() return 1, 1, 1, 0 end) -- fill transparent white
    id:setPixel(1, 1, 1, 1, 1, 1)                 -- set middle pixel
    local q = assert(atlas:add(id))
    local x, y = q:getViewport()
    -- Now define it to be 1x1 instead of 3x3
    q:setViewport(x + 1, y + 1, 1, 1, g.getAtlas():getDimensions())
    nameToQuad["1x1"] = q
end



--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------

local bigCache = {}
local smolCache = {}
local fbCache = {}

local function getFallbackFonts(size)
    if not fbCache[size] then
        fbCache[size] = love.graphics.newFont("assets/fonts/unifont-17.0.03.otf", size, "mono", size / 16)
    end
    return fbCache[size]
end

---@param size number? MUST BE MULTIPLE OF 16.
---@return love.Font
function g.getBigFont(size)
    size = size or 16 -- genera
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not bigCache[size] then
        local f = love.graphics.newFont("assets/fonts/Smart 9h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        bigCache[size] = f
    end
    return bigCache[size]
end

---@param size number? MUST BE MULTIPLE OF 16.
---@return love.Font
function g.getSmallFont(size)
    size = size or 16
    assert(size % 16 == 0, "Size must by divisible by 16")
    if not smolCache[size] then
        local f = love.graphics.newFont("assets/fonts/Match 7h.ttf", size, "mono", 1)
        f:setFallbacks(getFallbackFonts(size))
        smolCache[size] = f
    end
    return smolCache[size]
end


--------------------------------------------------------------------------------
-- Sound (SFX + BGM)
--------------------------------------------------------------------------------
do

----------
-- SFXs --
----------

---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playWorldSound(soundname, pitch, volume, pitchVar, volumeVar)
    -- World sounds are dropped once too many sources are already playing,
    -- so swarm-combat doesn't blow out the audio mixer.
    if love.audio.getActiveSourceCount() > consts.MAX_PLAYING_SOURCES then
        return false
    end
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end

---@param soundname string
---@param pitch number? (defaults to 1)
---@param volume number? (defaults to 1)
---@param pitchVar number? (pitch variance, default 0)
---@param volumeVar number? (volume variance, default 0)
function g.playUISound(soundname, pitch, volume, pitchVar, volumeVar)
    return sfx.play(soundname, pitch, volume, pitchVar, volumeVar)
end

---Call once per frame to reset the per-frame sound throttle.
function g.updateSfx()
    sfx.update()
end

local validExtensions = {
    wav = true,
    mp3 = true,
    ogg = true,
    flac = true
}

---@param path string
local function loadSound(path)
    local pathrev = path:reverse()
    local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

    if validExtensions[ext] then
        local basename = pathrev:sub(1, pathrev:find("/", 1, true) - 1):reverse()

        if #basename > 0 then
            local name = basename:sub(1, -#ext - 2)
            -- Leading-underscore files are skipped (eg bgm tracks live under bgm dirs).
            if name:sub(1, 1) ~= "_" then
                sfx.defineSound(name, path)
            end
        end
    end
end

g.walkDirectory("assets/sfx", loadSound)


----------
-- BGMs --
----------

-- Higher number means higher priority.
g.BGMID = {
    TITLE = 999, -- Title / menu
    GAMEPLAY = 1, -- In-run gameplay
    BOSS = 100, -- Boss theme
}

---@param path string
---@param prio integer
---@param isAmbient boolean?
local function registerBGMFromDirectories(path, prio, isAmbient)
    ---@type string[]
    local files = {}

    g.walkDirectory(path, function(filename)
        local pathrev = filename:reverse()
        local ext = pathrev:sub(1, (pathrev:find(".", 1, true) or 1) - 1):reverse():lower()

        if validExtensions[ext] then
            local basename = pathrev:sub(1, pathrev:find("/", 1, true) - 1):reverse()

            if #basename > 0 then
                local name = basename:sub(1, -#ext - 2)
                if name:sub(1, 1) ~= "_" then
                    files[#files + 1] = filename
                end
            end
        end
    end)

    if #files == 0 then
        error("no bgm files in " .. path)
    end

    return bgm.register(prio, files, isAmbient)
end

-- We cannot use g.walkDirectory directly because we need all the files first,
-- then register the BGM in one go via bgm.register.
--[[
registerBGMFromDirectories("assets/bgm/boss", g.BGMID.BOSS, false)
registerBGMFromDirectories("assets/bgm/gameplay", g.BGMID.GAMEPLAY, true)
registerBGMFromDirectories("assets/bgm/title", g.BGMID.TITLE, true)
]]

---Request playing a specific BGM ID. Must be called every frame the music
---should keep playing; the highest-priority request wins.
---@param id integer BGM ID. Use `g.BGMID` for the fixed constants.
function g.requestBGM(id)
    return bgm.request(id)
end

end












---------------------------------------------------------------
--- Entity rendering
---------------------------------------------------------------


local function drawIceCube(ent, x, y, sx,sy)
    local W,H,_ = 16,16,nil
    local quad = g.getImageQuad(ent.image)
    _,_,W,H = quad:getViewport()
    W = W+10
    H = H+10
    lg.setColor(1,1,1,0.5)
    g.drawImageContained("ice_cube", x-W/2, y-H/2, W,H)
end


local HEALTHBAR_ON_TOP = true
-- true if healthbar on top, 
-- false implies healthbar on bottom

local ENEMY_HEALTHBAR_COLOR = g.snapToPalette(1, 0.1, 0.1)
local ALLY_HEALTHBAR_COLOR = g.snapToPalette(0.1, 1, 0.1)
local NEUTRAL_HEALTHBAR_COLOR = g.snapToPalette(0.1, 0.4, 1)


---@param ent ecs.Entity
---@param x number
---@param y number
local function drawHealthBar(ent, x,y)
    if not ent.maxHealth then return end
    local w, h = 16, 2
    local frac = ent.health / ent.maxHealth

    local oy = -2
    if HEALTHBAR_ON_TOP then
        local _w,hhh = g.getImageSize(ent.image)
        oy= -hhh - 4
    end

    -- black outline
    local out=2
    lg.setColor(0, 0, 0)
    lg.rectangle("fill", x - w/2 - out, y + oy - out, w + out*2, h + out*2)

    local lagFrac = helper.clamp((ent.health + (ent._damageLagAmount or 0)) / ent.maxHealth, 0, 1)
    -- white lagged
    lg.setColor(1, 1, 1)
    lg.rectangle("fill", x - w/2, y + oy, w * lagFrac, h)

    -- green healthbar for allies, red for enemies
    if ent.team == "enemy" then
        lg.setColor(ENEMY_HEALTHBAR_COLOR)
    elseif ent.team == "ally" then
        lg.setColor(ALLY_HEALTHBAR_COLOR)
    else -- neutral unit
        lg.setColor(NEUTRAL_HEALTHBAR_COLOR)
    end
    lg.rectangle("fill", x - w/2, y + oy, w * frac, h)

    -- status effect tip segments (drawn right-to-left from tip)
    local pxPerHp = w / ent.maxHealth
    local right = x - w/2 + w * frac
    local remaining = ent.health
    local function drawTip(hp, color)
        hp = math.min(hp, remaining)
        if hp <= 0 then return end
        lg.setColor(color)
        lg.rectangle("fill", right - hp * pxPerHp, y + oy, hp * pxPerHp, h)
        right = right - hp * pxPerHp
        remaining = remaining - hp
    end
    drawTip(5 * (ent.poisonAmount or 0), g.COLORS.POISON)
    drawTip((ent.burnTime or 0) * consts.BURN_DPS, g.COLORS.BURN)

    if ent.armor then
        local FLASH_DUR = 0.15
        local armorFlash = math.max(0, FLASH_DUR - (ent._timeSinceLostArmor or 0xfff))/FLASH_DUR
        local armorH = 6
        local armorY = y + h + oy
        local ratio = math.min(1,(ent.armor)/6)
        lg.setColor(0,0,0)
        lg.rectangle("fill", x-w/2, armorY, w*ratio, armorH)
        local pad=2
        lg.setColor(0.5,0.5,0.5)
        lg.rectangle("fill", x-w/2 + pad, armorY + pad, ratio*(w-pad*2), armorH-pad*2)
        if armorFlash then
            lg.setColor(1,1,1, armorFlash)
            lg.rectangle("fill", x-w/2, armorY, w*ratio, armorH)
        end
        lg.setColor(1,1,1)
        g.drawImage("armor_healthbar_icon", x-w/2 - 2, armorY + 2)
        if armorFlash > 0 then
            lg.setColor(1,1,1, armorFlash)
            g.drawImage("armor_healthbar_icon_white", x-w/2 - 2, armorY + 2)
        end
    end
end



---@param ent ecs.Entity
---@param x number
---@param y number
function g.drawEntity(ent, x, y)
    local entScale = g.ask("getEntityScale", ent) * (ent.scale or 1)
    local sx, sy = (ent.sx or 1) * (ent.faceDir or 1) * entScale, (ent.sy or 1) * entScale
    if ent.onDraw then
        ent:onDraw(x, y)
    end
    local bodyRot = 0
    local walkBounce, walkWobble = 0, 0
    if ent._walkTime and ent._walkTime > 0 and ent.walkAnimation then
        local wa = assert(ent.walkAnimation)
        local t = ent._walkTime * wa.speed
        walkBounce = -math.abs(math.sin(t)) * wa.bounceHeight
        walkWobble = math.sin(t) * wa.rotationAmount
    end
    if ent.image then
        local HIT_HEAL_COLOR_INDICATOR_DURATION = 0.25
        local col = ent.color or objects.Color.WHITE

        local timeSinceDmgd = ent._timeSinceDamaged or 0xfffffff
        local timeSinceHeald = ent._timeSinceHealed or 0xfffffff
        local timeSince = math.min(timeSinceDmgd, timeSinceHeald)
        local amount = math.max(0, HIT_HEAL_COLOR_INDICATOR_DURATION - timeSince) / HIT_HEAL_COLOR_INDICATOR_DURATION
        if amount > 0 then
            if timeSinceDmgd < timeSinceHeald then
                col = col:lerp(g.COLORS.DAMAGE, amount)
            elseif timeSinceHeald < timeSinceDmgd then
                col = col:lerp(g.COLORS.HEAL, amount)
            end
        end

        lg.setColor(col[1], col[2], col[3], col[4] * (ent.alpha or 1))
        local rot = (ent.rot or 0) + bodyRot + (ent.damageJolt or 0) + walkWobble
        g.drawImageOffset(ent.image, x + (ent.ox or 0), y + (ent.oy or 0) + walkBounce, rot, sx, sy, 0.5, 0.95, ent.kx, ent.ky)

        if ent.frozenTime and ent.frozenTime > 0 then
            drawIceCube(ent, x,y, sx,sy)
        end
    end
    if DEV_SHOW_RANGE and ent.attackRange then
        lg.setColor(1,1,1,0.08 * math.min(1, (100/ent.attackRange)))
        lg.circle("line", x,y, ent.attackRange)
    end
    if ent.health then
        lg.setColor(1,1,1)
        drawHealthBar(ent, x,y)
    end
end








--------------------------------------------------------------------------------
-- Event Bus / Question Bus
--------------------------------------------------------------------------------

local definedEvents = {}
local questions = {}

-- global handler caches: name -> {func, func, ...}, rebuilt each frame by g.pollHandlers.
local handlerCache = {}

function g.defineEvent(ev)
    assert(not definedEvents[ev], "Event already defined: " .. ev)
    definedEvents[ev] = true
    handlerCache[ev] = {}
end

function g.isEvent(ev)
    return definedEvents[ev] == true
end

function g.defineQuestion(question, reducer, defaultValue)
    assert(not questions[question], "Question already defined: " .. question)
    questions[question] = {
        reducer = reducer,
        defaultValue = defaultValue,
    }
    handlerCache[question] = {}
end

function g.getQuestionInfo(q)
    return questions[q]
end

local _polling = false

-- Add a handler table for this frame only. Only valid inside scene:pollHandlers.
function g.addHandler(handler)
    assert(_polling, "g.addHandler called outside of g.pollHandlers!")
    for key, func in pairs(handler) do
        local list = handlerCache[key]
        assert(list, "Unknown event/question: " .. tostring(key))
        list[#list + 1] = func
    end
end

local _resetCallEventCounts

-- Called once per frame. Clears all handlers, then asks the scene to re-register them.
function g.pollHandlers()
    _resetCallEventCounts()
    for _, list in pairs(handlerCache) do
        table_clear(list)
    end
    _polling = true
    local sc = sceneManager.getCurrentScene()
    if sc and sc.pollHandlers then
        sc:pollHandlers()
    end
    _polling = false
end


local MAX_EVENT_CALLS_PER_FRAME = consts.MAX_EVENT_CALLS_PER_FRAME
local EVENT_COUNTS = {} -- [event] -> integer

function _resetCallEventCounts()
    for k in pairs(EVENT_COUNTS) do
        EVENT_COUNTS[k] = 0
    end
end

-- Fire an event. No return value.
-- Order: global handlers, then ent[ev].
function g.call(ev, arg1, ...)
    local ct = EVENT_COUNTS[ev] or 0
    if ct >= MAX_EVENT_CALLS_PER_FRAME then
        return
    end
    ct = ct + 1; EVENT_COUNTS[ev] = ct

    local list = handlerCache[ev]
    for i = 1, #list do
        list[i](arg1, ...)
    end

    if type(arg1) ~= "table" then return end

    if arg1[ev] then
        arg1[ev](arg1, ...)
    end
end

-- Ask a question. Returns reduced value.
-- Order: global handlers, then ent[q].
function g.ask(q, arg1, ...)
    local t = questions[q]
    if not t then
        error("Invalid question: " .. tostring(q))
    end
    local reducer, val = t.reducer, t.defaultValue

    local list = handlerCache[q]
    for i = 1, #list do
        val = reducer(val, list[i](arg1, ...))
    end

    if type(arg1) == "table" then
        if arg1[q] then
            val = reducer(val, arg1[q](arg1, ...))
        end
    end

    return val
end



--------------------------------------------------------------------------------
-- ECS accessors
--------------------------------------------------------------------------------

local currentECS

---@return ecs.ECSWorld
function g.getECS()
    return assert(currentECS, "ecs not active")
end

--- Non-asserting accessor: returns the active ECS, or nil when no ECS is running.
---@return ecs.ECSWorld?
function g.tryGetECS()
    return currentECS
end

---@param ecs ecs.ECSWorld
function g.setCurrentECS(ecs)
    currentECS = ecs
end




--------------------------------------------------------------------------------
-- Cards
--------------------------------------------------------------------------------

local CARD_DEFS = {} -- [id] -> def table (see card API in notes/SKAHD_TASKS.md)
local CARD_LIST = {} -- ordered list of ids

---@class g.Card: objects.Class
---@field cardId string
---@field def table
local Card = objects.Class("g:Card")

---@return number
function Card:getCost()
    local def = self.def
    local cost = def.cost or 0
    if def.getCostModifier then
        cost = cost + def.getCostModifier(self)
    end
    return cost
end

--- Fires the once-only cast hook. Per-player hooks (onCastPlayer) get wired up
--- once a player-iteration API exists.
function Card:cast()
    if self.def.onCast then
        self.def.onCast(self)
    end
end

---@class g.CardDef
---@field image string
---@field cost number
---@field getCostModifier (fun(card: g.Card): number)? Returns a cost delta applied on top of `cost`.
---@field init (fun(card: g.Card, ...: any): any)? Runs once per instance; receives g.newCardInstance's extra args.
---@field drawCastPreview (fun(card: g.Card, player: ecs.Entity))? Preview drawn once while casting.
---@field drawCastPreviewPlayer (fun(card: g.Card, player: ecs.Entity))? Preview drawn per player while casting.
---@field onCast (fun(card: g.Card))? Fires once on cast, regardless of player count.
---@field onCastPlayer (fun(card: g.Card, player: ecs.Entity))? Fires once per player on cast.

---@param card_id string
---@param ctype g.CardDef
function g.defineCard(card_id, ctype)
    assert(not CARD_DEFS[card_id], "Duplicate card type: " .. card_id)
    CARD_DEFS[card_id] = ctype
    CARD_LIST[#CARD_LIST + 1] = card_id
end

---@param card_id string
---@return table?
function g.getCardDef(card_id)
    return CARD_DEFS[card_id]
end

function g.getCardList()
    return CARD_LIST
end

--- Creates a new card instance. Extra args are forwarded to the def's init.
---@param card_id string
---@param ... unknown
---@return g.Card
function g.newCardInstance(card_id, ...)
    local def = CARD_DEFS[card_id]
    assert(def, "Unknown card type: " .. tostring(card_id))
    local card = Card()
    card.cardId = card_id
    card.def = def
    if def.init then
        def.init(card, ...)
    end
    return card
end

---@param card g.Card
---@param x number
---@param y number
---@param rot number?
---@param scale number?
function g.drawCard(card, x,y, rot, scale)
    scale = scale or 1
    g.drawImage(card.def.image, x,y, r, scale,scale)
end


--------------------------------------------------------------------------------
-- Current run
--------------------------------------------------------------------------------

---@type g.Run?
local currentRun = nil

---@param run g.Run?
function g.setRun(run)
    currentRun = run
end

---@return g.Run?
function g.getRun()
    return currentRun
end

---@return boolean
function g.hasRun()
    return currentRun ~= nil
end





--------------------------------------------------------------------------------
-- Entity definition / spawning
--------------------------------------------------------------------------------

local ENTITY_DEFS = {} -- [id] -> metatable {__index = def}
local ENTITY_LIST = {} -- ordered list of ids
local currentEntityId = 0

---@param id string
---@param def table
function g.defineEntity(id, def)
    assert(not ENTITY_DEFS[id], "Duplicate entity type: " .. id)
    assert(def.x == nil and def.y == nil and def.type == nil and def._world == nil, "x/y/type/_world are reserved")
    for k in pairs(Entity) do
        assert(def[k] == nil, "Entity def '" .. id .. "' cannot override base method: " .. k)
    end
    def.type = id
    -- Auto-assign a sprite named after the entity id, unless the entity renders
    -- itself via a custom onDraw (in which case it needs no sprite).
    if def.image == nil and not def.onDraw then
        def.image = id
    end
    for k, v in pairs(Entity) do
        def[k] = v
    end
    local mt = {__index = def}
    ENTITY_DEFS[id] = mt
    ENTITY_LIST[#ENTITY_LIST + 1] = id
end

--- we need this coz sometimes we need fields to be set immediately BEFORE qbuses or anything run
---@param id string
---@param x number
---@param y number
---@param initFunc (fun(e:ecs.Entity))?
---@param ... unknown
---@return ecs.Entity
function g.spawnEntityWithInit(id, x, y, initFunc, ...)
    local mt = ENTITY_DEFS[id]
    assert(mt, "Unknown entity type: " .. tostring(id))
    local ecs = g.getECS()
    currentEntityId = currentEntityId + 1
    local ent = setmetatable({
        id = currentEntityId,
        x = x, y = y, type = id,
        _world = ecs,
    }, mt)
    if ent.init then
        ent:init(...)
    end
    if initFunc then
        initFunc(ent)
    end
    ecs:addEntity(ent)
    g.call("entitySpawned", ent)
    return ent
end

---@param id string
---@param x number
---@param y number
---@param ... unknown
---@return ecs.Entity
function g.spawnEntity(id, x, y, ...)
    return g.spawnEntityWithInit(id, x, y, nil, ...)
end

---@param id string
---@return ecs.Components
function g.getEntityDef(id)
    local mt = ENTITY_DEFS[id]
    return mt and mt.__index
end

function g.getEntityList()
    return ENTITY_LIST
end


--------------------------------------------------------------------------------
-- Combat
--------------------------------------------------------------------------------

---@param ent ecs.Entity
---@return boolean
function g.isAlive(ent)
    return not ent.___removed
end

---@param ent ecs.Entity
---@param healAmount number
---@param healerEnt ecs.Entity?
function g.healEntity(ent, healAmount, healerEnt)
    if not g.isAlive(ent) then return end

    local oldHealth = ent.health
    ent.health = math.min(ent.maxHealth, ent.health + healAmount)
    local finalHeal = ent.health - oldHealth

    if finalHeal > 0 then
        ent._timeSinceHealed = 0
        g.call("entityHealed", ent, finalHeal, healerEnt)
        g.call("onHitHeal", healerEnt, finalHeal, ent)
    end
end

---@param target ecs.Entity
---@param damage number
---@param attacker ecs.Entity?
---@param ignoreQuestionBuses boolean?
function g.damageEntity(target, damage, attacker, ignoreQuestionBuses)
    if not g.isAlive(target) then return end

    local finalDmg = math.max(0, damage)
    if not ignoreQuestionBuses then
        finalDmg = finalDmg * g.ask("getDamageTakenMultiplier", target, attacker)
    end

    target._damageLagAmount = (target._damageLagAmount or 0) + finalDmg

    target.health = target.health - finalDmg
    target._timeSinceDamaged = 0

    if attacker then
        g.call("onHitDamage", attacker, damage, target)
    end
    g.call("entityDamaged", target, damage)

    if attacker and attacker.lifesteal then
        g.healEntity(attacker, damage * attacker.lifesteal, attacker)
    end

    if target.health <= 0 then
        g.killEntity(target, attacker)
    end
end

---@param ent ecs.Entity
---@param killer ecs.Entity?
function g.killEntity(ent, killer)
    if ent.___dead or not g.isAlive(ent) then return end
    ent.___dead = true
    ent.health = 0
    g.call("entityDeath", ent, killer)
    if killer then
        g.call("onKill", killer, ent)
    end
    ent:getWorld():removeEntity(ent)
end



--------------------------------------------------------------------------------
-- Scene / camera / coordinate spaces
--------------------------------------------------------------------------------

---@return table scene
---@return string name
function g.getCurrentScene()
    return sceneManager.getCurrentScene()
end

--- Convert screen coordinates to world coordinates using the current scene's
--- camera. Returns the input unchanged if the scene has no camera.
---@param x number
---@param y number
---@return number x
---@return number y
function g.screenToWorld(x, y)
    local scene = sceneManager.getCurrentScene()
    if scene and scene.camera then
        return scene.camera:toWorld(x, y)
    end
    return x, y
end

--- Convert world coordinates to screen coordinates using the current scene's
--- camera. Returns the input unchanged if the scene has no camera.
---@param x number
---@param y number
---@return number x
---@return number y
function g.worldToScreen(x, y)
    local scene = sceneManager.getCurrentScene()
    if scene and scene.camera then
        return scene.camera:toScreen(x, y)
    end
    return x, y
end


--------------------------------------------------------------------------------
-- Text popups
--------------------------------------------------------------------------------

--- Spawn a floating text popup anchored to a world position. The position is
--- projected to the screen via the current camera; popups live in screen space.
---@param x number world x
---@param y number world y
---@param richtxt string|richtext.ParsedText
---@param args textPopupService.args?
function g.addWorldTextPopup(x, y, richtxt, args)
    local sx, sy = g.worldToScreen(x, y)
    textPopupService.addPopup(sx, sy, richtxt, args)
end

--- Spawn a floating text popup at a fixed screen position.
---@param x number screen x
---@param y number screen y
---@param richtxt string|richtext.ParsedText
---@param args textPopupService.args?
function g.addUITextPopup(x, y, richtxt, args)
    -- TODO: ensure ui is wired up
    x,y = ui.getUIScalingTransform():inverseTransformPoint(x,y)
    textPopupService.addPopup(x, y, richtxt, args)
end


--------------------------------------------------------------------------------
-- Gold Infra
--------------------------------------------------------------------------------

--- Adds gold to an entity
--- @param ent ecs.Entity
--- @param amount number
function g.addGold(ent, amount)
    if not ent.gold then return end
    ent.gold = (ent.gold or 0) + amount
end

--- Try to spend gold from an entity
--- @param ent ecs.Entity
--- @param amount number
function g.trySpendGold(ent, amount)
    if not ent.gold then return end
    if ent.gold >= amount then
        ent.gold = ent.gold - amount
        return true
    end
    return false
end

return g
