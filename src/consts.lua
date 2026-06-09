

---@class g.consts
local consts = {}

consts.DEV_MODE = not not (love.filesystem.getInfo(".git", "directory") and os.getenv("DISABLE_DEV_MODE") ~= "1")
consts.TEST = consts.DEV_MODE
consts.PROFILING = false
consts.CONSOLE_LOG_LEVEL = "debug"
consts.FILE_LOG_LEVEL = "none"
consts.GAME_VERSION = 0

-- Max simultaneous audio sources before world sounds get dropped.
consts.MAX_PLAYING_SOURCES = 14

consts.TAU = 2 * math.pi

consts.BURN_DPS = 2 * math.pi

-- Downward accel for entities with a vz (z-height), eg arcing projectiles.
consts.GRAVITY = 300

-- Max distinct event-type dispatches per frame (avoids infinite loops robustly).
consts.MAX_EVENT_CALLS_PER_FRAME = 20

return consts
