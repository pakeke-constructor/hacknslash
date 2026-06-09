


---@class controls.controlService
local controlService = {}


---@param controlEnum string
---@return boolean
function controlService.isDown(controlEnum)
end



---@param controlEnum string
---@param func function
function controlService.on(controlEnum, func)
end


---@param controlEnum string
function controlService.wasJustPressed(controlEnum)
    -- returns `true` on the frame AFTER a controlEnum was released
end


---@param controlEnum string
function controlService.defineControl(controlEnum)
end



---@alias controls.Control string
-- "key:s", "key:w"
-- "mouse:button_1", "mouse:button_2"
-- etc,etc


---@param controls table<string, controls.Control[]>
function controlService.setControls(controls)
    -- { [controlEnum]: {"key:a", "key:b"} }
    -- inverts controls, sets the current control bindings
end



function controlService.keypressed(key, scancode, isrepeat)
end

function controlService.mousemoved(key, scancode, isrepeat)
end

function controlService.setPointer(key, scancode, isrepeat)
end

function controlService.getPointer(key, scancode, isrepeat)
end







return controlService

