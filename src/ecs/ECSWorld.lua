local objects = require("src.modules.objects.objects")
local table_clear = require("table.clear")
local PixelCanvas = require("src.modules.PixelCanvas")

---@class ecs.ECSWorld: objects.Class
---@field public data table<string, any>
local ECSWorld = objects.Class("ecs:ECSWorld")


---@class ecs.System
---@field public ecs ecs.ECSWorld


local PARTITION_CHUNKSIZE = 32

function ECSWorld:init()
    ---@type objects.BufferedSet<ecs.Entity>
    self.entities = objects.BufferedSet()

    self.data = {} -- system-storage

    self.players = {} -- list of player entities, rebuilt each update

    self.backCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.frontCanvas = PixelCanvas.new(love.graphics.getDimensions())
    self.border = nil -- {0, 0, w, h} or nil for no border

    self.componentIndex = {} -- [componentName] -> {ent, ent, ...}
    self.trackedComponents = objects.Set()
    ---@type table<string, objects.Partition<ecs.Entity>>
    self.partitions = {} -- [partitionId] -> objects.Partition<ecs.Entity> (created on demand)

    -- Load & initialize systems. Each system is a plain table of event/question
    -- handler methods plus an optional :init(). Every ECSWorld gets its own
    -- fresh instance so per-run state (eg self.foo) never leaks between worlds.
    self.systems = {}
    self.systemsByName = {} -- [name] -> system, for O(1) getSystem
    self:_loadSystems()
end


local SYSTEMS_DIR = "src/ecs/systems"

-- Keys on a system table that are lifecycle/bookkeeping, never event handlers.
local RESERVED_SYSTEM_KEYS = {
    init = true,
    ecs = true,
    name = true,
    _handlers = true,
}

-- Auto-discover every system module under SYSTEMS_DIR and load it.
function ECSWorld:_loadSystems()
    local files = love.filesystem.getDirectoryItems(SYSTEMS_DIR)
    table.sort(files) -- deterministic load order
    for _, file in ipairs(files) do
        if file:sub(-4) == ".lua" then
            self:_loadSystem(file:sub(1, -5))
        end
    end
end

---@param name string filename of the system (without .lua)
function ECSWorld:_loadSystem(name)
    local module = require("src.ecs.systems." .. name)

    -- Fresh per-world instance: copy the module's methods/fields onto a new
    -- table so :init() state is isolated per ECSWorld.
    local system = {}
    for k, v in pairs(module) do
        system[k] = v
    end
    system.ecs = self
    system.name = name

    -- Pre-bind every event/question handler to this instance, so handlers run
    -- with the system as `self` and are closured once (not rebuilt each frame).
    local handlers = {}
    for key, fn in pairs(system) do
        if type(fn) == "function" and not RESERVED_SYSTEM_KEYS[key] then
            assert(g.isEvent(key) or g.getQuestionInfo(key),
                "System '" .. name .. "' has handler '" .. key ..
                "' which is not a defined event or question")
            handlers[key] = function(...) return fn(system, ...) end
        end
    end
    system._handlers = handlers

    self.systems[#self.systems + 1] = system
    self.systemsByName[name] = system

    if system.init then
        system:init()
    end
end

function ECSWorld:setBorder(w, h)
    self.border = {0, 0, w, h}
end

---@param e ecs.Entity
function ECSWorld:addEntity(e)
    self.entities:addBuffered(e)
end

---@param e ecs.Entity
function ECSWorld:removeEntity(e)
    e.___removed = true
    self.entities:removeBuffered(e)
end

---@param e ecs.Entity
local function entHas(e, k)
    if rawget(e, k) ~= nil then return true end
    local mt = getmetatable(e)
    local base = mt and rawget(mt, "__index")
    return type(base) == "table" and base[k] ~= nil
end

function ECSWorld:_rebuildComponentIndex()
    local idx = self.componentIndex
    for _, list in pairs(idx) do
        table_clear(list)
    end
    local tracked = self.trackedComponents
    for ti = 1, tracked.len do
        local k = tracked[ti]
        local list = idx[k]
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, k) then
                list[#list + 1] = e
            end
        end
    end
end

function ECSWorld:_rebuildPartitions()
    for _, part in pairs(self.partitions) do
        part:clear()
    end
    for i = 1, self.entities.len do
        local e = self.entities[i]
        local p = e.partitions
        if p then
            for j = 1, #p do
                local pid = p[j]
                local part = self.partitions[pid]
                if not part then
                    part = objects.Partition(PARTITION_CHUNKSIZE)
                    self.partitions[pid] = part
                end
                part:add(e, e.x, e.y)
            end
        end
    end
end

function ECSWorld:addSystemHandlers()
    for i = 1, #self.systems do
        g.addHandler(self.systems[i]._handlers)
    end
end


---@return ecs.Entity[]
function ECSWorld:getPlayers()
    return self.players
end


---@param name string filename of the system (without .lua)
---@return ecs.System?
function ECSWorld:getSystem(name)
    return self.systemsByName[name]
end


function ECSWorld:update(dt)
    self.entities:flush()
    self:_rebuildPartitions()
    self:_rebuildComponentIndex()
    g.call("preUpdate", dt)
    table_clear(self.players)
    for i = 1, self.entities.len do
        local e = self.entities[i]
        if e.player then
            self.players[#self.players + 1] = e
        end
        if not e.physics then
            local vx, vy = g.getVel(e)
            if vx ~= 0 then e.x = e.x + vx * dt end
            if vy ~= 0 then e.y = e.y + vy * dt end
        end
        if e._knockVx then
            local decay = math.exp(-10 * dt)
            e._knockVx = e._knockVx * decay
            e._knockVy = e._knockVy * decay
            if math.abs(e._knockVx) < 0.5 and math.abs(e._knockVy) < 0.5 then
                e._knockVx, e._knockVy = nil, nil
            end
        end
        if e.vz then
            e.vz = e.vz - consts.GRAVITY * dt
            e.z = math.max(0, (e.z or 0) + e.vz * dt)
        end
        if e.health then
            if e.maxHealth and e.health > e.maxHealth then
                e.health = e.maxHealth
            end
            e._timeSinceDamaged = (e._timeSinceDamaged or 0xfffffffff) + dt
            e._timeSinceHealed = (e._timeSinceHealed or 0xfffffffff) + dt
            if e._damageLagAmount and e._damageLagAmount > 0 then
                e._damageLagAmount = e._damageLagAmount * math.exp(-18 * dt)
                if e._damageLagAmount < 0.01 then
                    e._damageLagAmount = nil
                end
            end
        end
        if e.onUpdate then
            e:onUpdate(dt)
        end
        if e.lifetime then
            e.lifetime = e.lifetime - dt
            if e.lifetime <= 0 then
                self:removeEntity(e)
            end
        end
    end
    local border = self.border
    if border then
        for i = 1, self.entities.len do
            local e = self.entities[i]
            local cx = math.min(math.max(e.x, border[1]), border[3])
            local cy = math.min(math.max(e.y, border[2]), border[4])
            e.x, e.y = cx, cy
        end
    end
    g.call("postUpdate", dt)
    self._secondAccum = (self._secondAccum or 0) + dt
    if self._secondAccum >= 1 then
        self._secondAccum = self._secondAccum - 1
        g.call("perSecondUpdate", dt)
    end
    self.entities:flush()
end

local function getDrawY(e)
    return e.y - (e.z or 0) / 2
end

local function sortOrder(a, b)
    local ya = getDrawY(a) + (a.drawOrder or 0)
    local yb = getDrawY(b) + (b.drawOrder or 0)
    if ya == yb then return a.id < b.id end
    return ya < yb
end

function ECSWorld:draw(transform)
    g.setCurrentECS(self)
    if transform then
        self.backCanvas:start(transform)
    end
    g.call("preDraw")
    if transform then
        self.backCanvas:finish()
    end

    local list = {}
    for i = 1, self.entities.len do
        list[#list + 1] = self.entities[i]
    end
    table.sort(list, sortOrder)
    for i = 1, #list do
        local e = list[i]
        local dy = getDrawY(e)
        g.drawEntity(e, e.x, dy)
        g.call("drawEntity", e, e.x, dy)
    end

    if transform then
        self.frontCanvas:start(transform)
    end
    g.call("postDraw")
    if transform then
        self.frontCanvas:finish()
    end
end


---@param component string
---@return fun(table: ecs.Entity[], i?: integer):(integer,ecs.Entity)
---@return ecs.Entity[]
---@return integer
function ECSWorld:iterate(component)
    local list = self.componentIndex[component]
    if not list then
        list = {}
        self.componentIndex[component] = list
        self.trackedComponents:add(component)
        for i = 1, self.entities.len do
            local e = self.entities[i]
            if entHas(e, component) then
                list[#list + 1] = e
            end
        end
    end
    return ipairs(list)
end



---@param partitionId string
---@param x number
---@param y number
---@param fn fun(ent: ecs.Entity)
---@param range number
function ECSWorld:iteratePartition(partitionId, x, y, fn, range)
    local part = self.partitions[partitionId]
    if part then
        part:query(x, y, fn, range)
    end
end

return ECSWorld
