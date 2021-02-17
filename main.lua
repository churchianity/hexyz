

math.randomseed(os.time())
math.random()
math.random()
math.random()
math.random()

do
    local width, height, title = 1920, 1080, "hexyz"

    WIN = am.window{
        width       = width,
        height      = height,
        title       = title,
        highdpi     = true,
        letterbox   = true,
        --mode        = "fullscreen",
        --projection  = projection
    }

    OFF_SCREEN = vec2(width * 2, 0) -- arbitrary location garunteed to be offscreen
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
require "src/grid"
require "src/mob"
require "src/projectile"
require "src/tower"

-- global audio settings
MUSIC_VOLUME = 0.1
SFX_VOLUME   = 0.1

function main_action() end
function main_scene() end

WIN.scene = am.group()
game_init()
noglobals()

