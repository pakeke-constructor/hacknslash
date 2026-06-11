

-- Steers entities' velocity toward a target each frame, preserving speed.
-- Fires onArrive (and drops the component) once it reaches the target.
local homing = {}


local function radius(ent)
    return (ent.physics and ent.physics.radius) or 10
end


function homing:preUpdate(dt)
    for _, ent in self.ecs:iterate("homeTowardsEntity") do
        local h = ent.homeTowardsEntity
        local target = h.target

        -- target gone -> stop homing
        if not target or target.___removed then
            ent.homeTowardsEntity = nil
            goto continue
        end

        local dx, dy = target.x - ent.x, target.y - ent.y
        local dist = math.sqrt(dx * dx + dy * dy)

        -- arrived?
        if dist <= radius(ent) + radius(target) then
            ent.homeTowardsEntity = nil
            if h.onArrive then h.onArrive(ent, target) end
            goto continue
        end

        -- steer toward target. keep current speed, else fall back to moveSpeed
        local vx, vy = ent.vx or 0, ent.vy or 0
        local speed = math.sqrt(vx * vx + vy * vy)
        if speed == 0 then speed = ent.moveSpeed or 0 end
        ent.vx = dx / dist * speed
        ent.vy = dy / dist * speed

        ::continue::
    end
end


return homing
