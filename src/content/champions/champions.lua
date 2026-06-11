

-- Movement feel: ease velocity toward target via frame-rate-independent
local DEFAULT_SPEED = 250
local DEFAULT_ACCEL_TIME = 0.055 -- time to reach max speed
local DEFAULT_BRAKE_TIME = 0.095 -- time to reach speed 0


-- Below this speed with no input, we hard-zero velocity for a clean dead stop.
local STOP_EPSILON = 2


---Convert a "time to reach ~95% of target" into an exponential response rate.
local function timeToRate(t)
    if t <= 0 then return math.huge end -- 0 => instant snap
    return 3 / t
end

---Frame-rate-independent exponential approach toward `target`.
local function approach(current, target, rate, dt)
    return current + (target - current) * (1 - math.exp(-rate * dt))
end

local function doPlayerMovement(ent, dt)
    local dx, dy = controlService.getMoveAxis()
    local moving = (dx ~= 0 or dy ~= 0)

    local speed = ent.moveSpeed or DEFAULT_SPEED
    local tvx, tvy = dx * speed, dy * speed

    -- Determine responsiveness per axis: if we're decelerating along an axis
    -- (target pulls velocity toward zero or reverses it), use the snappier brake
    -- rate; otherwise use accel. This makes both stopping AND hard reversals
    -- feel tight while a held direction still has a touch of ramp-up weight.
    local accelRate = timeToRate(ent.accelTime or DEFAULT_ACCEL_TIME)
    local brakeRate = timeToRate(ent.brakeTime or DEFAULT_BRAKE_TIME)
    local vx, vy = ent.vx or 0, ent.vy or 0

    local rx = (tvx == 0 or tvx * vx < 0) and brakeRate or accelRate
    local ry = (tvy == 0 or tvy * vy < 0) and brakeRate or accelRate

    vx = approach(vx, tvx, rx, dt)
    vy = approach(vy, tvy, ry, dt)

    -- Snap to a clean stop so we don't drift forever on the exponential tail.
    if not moving then
        if math.abs(vx) < STOP_EPSILON then vx = 0 end
        if math.abs(vy) < STOP_EPSILON then vy = 0 end
    end

    ent.vx, ent.vy = vx, vy

    if dx ~= 0 then ent.faceDir = dx > 0 and 1 or -1 end
end



g.defineEntity("basic_champion", {
    player = true,
    autoAttack={
        drawCursor = nil, -- or function(ent) ... end
        range = 100,
    },

    image = "basic_champion",

    -- base stats (computed -> maxHealth/attackDamage/attackSpeed/attackRange by stats system)
    baseMaxHealth = 100,
    baseAttackDamage = 10,
    baseAttackSpeed = 1, -- attacks per second
    baseAttackRange = 100,

    moveSpeed = DEFAULT_SPEED,
    accelTime = DEFAULT_ACCEL_TIME,
    brakeTime = DEFAULT_BRAKE_TIME,

    gold = 0,
    partitions = {"player"},

    physics = { shape = "circle", radius = 7, mass = 1 },

    onUpdate = function (ent, dt)
        doPlayerMovement(ent, dt)
    end
})

