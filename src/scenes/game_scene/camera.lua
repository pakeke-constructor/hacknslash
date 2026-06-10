local objects = require("src.modules.objects.objects")

local lg = love.graphics

---@class game.Camera: objects.Class
---@field x number world position the camera is centered on
---@field y number
---@field scale number zoom
---@field transform love.Transform rebuilt once per frame by :update
local Camera = objects.Class("game:Camera")

---@param scale number
function Camera:init(scale)
    self.x = 0
    self.y = 0
    self.scale = scale or 1
    self.transform = love.math.newTransform()
end

--- Recompute the transform. Call once per frame.
function Camera:update()
    local w, h = lg.getDimensions()
    local t = self.transform
    t:reset()
    t:translate(w / 2, h / 2)
    t:scale(self.scale, self.scale)
    t:translate(-self.x, -self.y)
end

---@return love.Transform
function Camera:getTransform()
    return self.transform
end

---@param x number screen x
---@param y number screen y
---@return number x, number y
function Camera:toWorld(x, y)
    return self.transform:inverseTransformPoint(x, y)
end

---@param x number world x
---@param y number world y
---@return number x, number y
function Camera:toScreen(x, y)
    return self.transform:transformPoint(x, y)
end

return Camera
