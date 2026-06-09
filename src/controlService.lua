

--[[
    controlService
    ==============
    An abstraction over raw keyboard/mouse input.

    Game code never asks "is the W key down?"; it asks "is MOVE_UP down?".
    The physical bindings (key:w, mouse:button_1, ...) can be remapped freely
    via `setControls` without touching gameplay code.

    HOW EDGES ARE DETECTED:
        `isDown` polls the live key/mouse state.
        Press/release edges (`wasJustPressed` / `wasJustReleased` / `on`) are
        driven by love's event callbacks, NOT by polling-diff. This catches a
        press+release that happens within a single frame, which a poll-diff
        would miss. love delivers all queued key/mouse events before
        love.update each frame, so an edge latched in `keypressed` is readable
        for the whole frame; `update` clears the latches at frame's end.

    WIRING (in main.lua):
        love.keypressed    -> controlService.keypressed
        love.keyreleased   -> controlService.keyreleased
        love.mousepressed  -> controlService.mousepressed
        love.mousereleased -> controlService.mousereleased
        love.update        -> controlService.update(dt)  AFTER gameplay reads controls

    USAGE:
        controlService.isDown("DASH")
        controlService.wasJustPressed("DASH")
        controlService.on("DASH", fn)              -- returns an unsubscribe fn
        local mx, my = controlService.getPointer() -- aim point (screen coords)
]]

---@class controls.controlService
local controlService = {}

local table_clear = require("table.clear")

local lk = love.keyboard
local lm = love.mouse


--------------------------------------------------------------------------------
-- Control enums
--------------------------------------------------------------------------------

-- Abstract control names used by gameplay code. Reference these instead of
-- raw strings so typos surface as nil-indexing rather than silent no-ops.
---@enum controls.ControlEnum
controlService.CONTROLS = {
    MOVE_UP    = "MOVE_UP",
    MOVE_DOWN  = "MOVE_DOWN",
    MOVE_LEFT  = "MOVE_LEFT",
    MOVE_RIGHT = "MOVE_RIGHT",

    DASH    = "DASH",
    ATTACK  = "ATTACK",
    SPECIAL = "SPECIAL",

    PAUSE = "PAUSE",
}


--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local definedControls = {} -- [enum] -> true
local bindings = {}        -- [enum] -> { parsedBinding, ... }   (for isDown polling)
local invMap = {}          -- [inputId] -> { enum, ... }         (for edge events)
local handlers = {}        -- [enum] -> { func, ... }

local justPressed = {}  -- [enum] -> bool   pressed-edge this frame
local justReleased = {} -- [enum] -> bool   released-edge this frame

-- Pointer override (eg gamepad aim). nil => fall back to the live mouse cursor.
local overrideX, overrideY
local lastMouseX, lastMouseY = lm.getPosition()


--------------------------------------------------------------------------------
-- Binding parsing
--------------------------------------------------------------------------------

---@alias controls.Control string
-- "key:s", "key:w"            -- love KeyConstant
-- "scancode:s"               -- love Scancode (layout-independent position)
-- "mouse:button_1", "mouse:2" -- mouse button index

-- A parsed binding's canonical id, eg "key:w" / "scancode:w" / "mouse:1".
-- Built to exactly match the ids reconstructed in the event callbacks below.
local function bindingId(b)
    return b.kind .. ":" .. b.value
end

---@param str controls.Control
local function parseControl(str)
    local kind, value = str:match("^(%w+):(.+)$")
    assert(kind, "Invalid control string: " .. tostring(str))

    if kind == "mouse" then
        local n = value:match("^button_(%d+)$") or value:match("^(%d+)$")
        assert(n, "Invalid mouse control: " .. str .. " (expected mouse:button_N)")
        return { kind = "mouse", value = tonumber(n) }
    elseif kind == "key" then
        return { kind = "key", value = value }
    elseif kind == "scancode" then
        return { kind = "scancode", value = value }
    end

    error("Unknown control kind '" .. kind .. "' in: " .. str)
end

---@param b table parsed binding
---@return boolean
local function isBindingDown(b)
    local kind = b.kind
    if kind == "key" then
        return lk.isDown(b.value)
    elseif kind == "scancode" then
        return lk.isScancodeDown(b.value)
    elseif kind == "mouse" then
        return lm.isDown(b.value)
    end
    return false
end


--------------------------------------------------------------------------------
-- Configuration
--------------------------------------------------------------------------------

---Register a control enum as valid. Bindings can only target defined controls.
---@param controlEnum controls.ControlEnum
function controlService.defineControl(controlEnum)
    assert(type(controlEnum) == "string", "controlEnum must be a string")
    definedControls[controlEnum] = true
    handlers[controlEnum] = handlers[controlEnum] or {}
end

---Set the active key/mouse bindings. Replaces any existing bindings.
---@param controls table<controls.ControlEnum, controls.Control[]>
function controlService.setControls(controls)
    -- { [controlEnum] = {"key:a", "key:b"}, ... }
    bindings = {}
    invMap = {}
    for enum, strs in pairs(controls) do
        assert(definedControls[enum], "Binding for undefined control: " .. tostring(enum))
        local parsed = {}
        for i = 1, #strs do
            local b = parseControl(strs[i])
            parsed[i] = b
            -- inverted lookup: physical input -> controls, used by the events.
            local id = bindingId(b)
            local list = invMap[id]
            if not list then list = {}; invMap[id] = list end
            list[#list + 1] = enum
        end
        bindings[enum] = parsed
    end
end


--------------------------------------------------------------------------------
-- Queries
--------------------------------------------------------------------------------

---Is the control currently held down?
---@param controlEnum controls.ControlEnum
---@return boolean
function controlService.isDown(controlEnum)
    assert(definedControls[controlEnum], "Undefined control: " .. tostring(controlEnum))
    local list = bindings[controlEnum]
    if not list then return false end
    for i = 1, #list do
        if isBindingDown(list[i]) then return true end
    end
    return false
end

---True for the single frame on which the control transitioned up -> down.
---@param controlEnum controls.ControlEnum
---@return boolean
function controlService.wasJustPressed(controlEnum)
    assert(definedControls[controlEnum], "Undefined control: " .. tostring(controlEnum))
    return justPressed[controlEnum] == true
end

---True for the single frame on which the control transitioned down -> up.
---@param controlEnum controls.ControlEnum
---@return boolean
function controlService.wasJustReleased(controlEnum)
    assert(definedControls[controlEnum], "Undefined control: " .. tostring(controlEnum))
    return justReleased[controlEnum] == true
end

---Register a callback fired on the pressed-edge of a control.
---@param controlEnum controls.ControlEnum
---@param func function
---@return function unsubscribe call to remove the handler
function controlService.on(controlEnum, func)
    assert(definedControls[controlEnum], "Undefined control: " .. tostring(controlEnum))
    assert(type(func) == "function", "expected function")
    local list = handlers[controlEnum]
    list[#list + 1] = func
    return function()
        for i = #list, 1, -1 do
            if list[i] == func then
                table.remove(list, i)
                return
            end
        end
    end
end

---Convenience: normalized movement vector from the four MOVE_* controls.
---Returns (0, 0) when no movement keys are held.
---@return number x
---@return number y
function controlService.getMoveAxis()
    local C = controlService.CONTROLS
    local x = (controlService.isDown(C.MOVE_RIGHT) and 1 or 0) - (controlService.isDown(C.MOVE_LEFT) and 1 or 0)
    local y = (controlService.isDown(C.MOVE_DOWN) and 1 or 0) - (controlService.isDown(C.MOVE_UP) and 1 or 0)
    if x ~= 0 and y ~= 0 then
        local inv = 1 / math.sqrt(2)
        x, y = x * inv, y * inv
    end
    return x, y
end


--------------------------------------------------------------------------------
-- Pointer / aim
--------------------------------------------------------------------------------

---The current aim pointer in SCREEN coordinates. Defaults to the mouse cursor;
---use `g.screenToWorld` to project into world space for aiming.
---Moving the mouse always reclaims control of the pointer (see `update`).
---@return number x
---@return number y
function controlService.getPointer()
    if overrideX then
        return overrideX, overrideY
    end
    return lm.getPosition()
end

---Override the aim pointer (eg from a gamepad right-stick). Pass nil to clear
---and fall back to the mouse.
---@param x number?
---@param y number?
function controlService.setPointer(x, y)
    overrideX, overrideY = x, y
end


--------------------------------------------------------------------------------
-- Event callbacks (forwarded from love.* in main.lua)
--------------------------------------------------------------------------------

local function pressEnum(enum)
    justPressed[enum] = true
    local hs = handlers[enum]
    for i = 1, #hs do hs[i]() end
end

-- Fire the press edge for every control bound to `id`. `seen` dedupes the rare
-- case where one physical input maps to the same control via two ids (eg a
-- control bound to both "key:w" and "scancode:w").
local function firePress(id, seen)
    local list = invMap[id]
    if not list then return end
    for i = 1, #list do
        local enum = list[i]
        if not seen[enum] then
            seen[enum] = true
            pressEnum(enum)
        end
    end
end

-- Releases just set a boolean, so duplicate sets are harmless (no dedupe).
local function fireRelease(id)
    local list = invMap[id]
    if not list then return end
    for i = 1, #list do
        justReleased[list[i]] = true
    end
end

---@param key string
---@param scancode string
---@param isrepeat boolean
function controlService.keypressed(key, scancode, isrepeat)
    if isrepeat then return end -- edges only; ignore OS key-repeat
    local seen = {}
    firePress("key:" .. key, seen)
    firePress("scancode:" .. scancode, seen)
end

---@param key string
---@param scancode string
function controlService.keyreleased(key, scancode)
    fireRelease("key:" .. key)
    fireRelease("scancode:" .. scancode)
end

---@param button integer
function controlService.mousepressed(_x, _y, button)
    firePress("mouse:" .. button, {})
end

---@param button integer
function controlService.mousereleased(_x, _y, button)
    fireRelease("mouse:" .. button)
end


--------------------------------------------------------------------------------
-- Per-frame housekeeping
--------------------------------------------------------------------------------

---Call once per frame, AFTER gameplay has read the controls. Clears the
---per-frame press/release edges and lets the mouse reclaim the aim pointer.
---@param dt number?
function controlService.update(dt)
    -- Moving the physical mouse takes the pointer back from any override.
    local mx, my = lm.getPosition()
    if mx ~= lastMouseX or my ~= lastMouseY then
        overrideX, overrideY = nil, nil
        lastMouseX, lastMouseY = mx, my
    end

    table_clear(justPressed)
    table_clear(justReleased)
end


--------------------------------------------------------------------------------
-- Default bindings
--------------------------------------------------------------------------------

do
    local C = controlService.CONTROLS
    for _, enum in pairs(C) do
        controlService.defineControl(enum)
    end

    controlService.setControls({
        [C.MOVE_UP]    = { "scancode:w", "key:up" },
        [C.MOVE_DOWN]  = { "scancode:s", "key:down" },
        [C.MOVE_LEFT]  = { "scancode:a", "key:left" },
        [C.MOVE_RIGHT] = { "scancode:d", "key:right" },

        [C.ATTACK]  = { "mouse:button_1" },
        [C.SPECIAL] = { "mouse:button_2" },
        [C.DASH]    = { "key:space", "key:lshift" },

        [C.PAUSE] = { "key:escape" },
    })
end


return controlService
