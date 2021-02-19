

settings = am.load_state("settings", "json") or {
    fullscreen = false,
    window_width = 1920,
    window_height = 1080,
    music_volume = 0.1,
    sfx_volume = 0.1,
}

math.randomseed(os.time())
math.random()
math.random()
math.random()
math.random()

do
    win = am.window{
        width     = settings.window_width,
        height    = settings.window_height,
        title     = "hexyz",
        mode      = settings.fullscreen and "fullscreen" or "windowed",
        highdpi   = true,
        letterbox = true,
        resizable = true, -- user should probably set their resolution instead of resizing the window, but hey.
    }
end

-- assets and/or trivial code
require "color"
require "sound"
require "texture"

require "src/entity"
require "src/extra"
require "src/geometry"
require "src/hexyz"
require "src/game"
require "src/gui"
require "src/grid"
require "src/mob"
require "src/projectile"
require "src/tower"

function main_action() end
function main_scene() end

win.scene = am.group()
game_init(nil)
noglobals()

