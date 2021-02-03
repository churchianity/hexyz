

math.randomseed(os.time())
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
require "src/gui"
require "src/mob"
require "src/projectile"
require "src/tower"


-- global audio settings
MUSIC_VOLUME = 0.1
SFX_VOLUME   = 0.1

MODES = { MAIN, GAME }
CURRENT_MODE = MODES.MAIN

-- top right display types
local TRDTS = {
    NOTHING,
    CENTERED_EVENQ,
    EVENQ,
    HEX,
    PLATFORM,
    PERF,
    SEED,
    TILE,
}
local TRDT = 0

function update_top_right_message(display_type)
    local str = ""
    if display_type == TRDTS.CENTERED_EVENQ then
        str = centered_evenq.x .. "," .. centered_evenq.y .. " (cevenq)"

    elseif display_type == TRDTS.EVENQ then
        str = evenq.x .. "," .. evenq.y .. " (evenq)"

    elseif display_type == TRDTS.HEX then
        str = hex.x .. "," .. hex.y .. " (hex)"

    elseif display_type == TRDTS.PLATFORM then
        str = string.format("%s %s lang %s", am.platform, am.version, am.language())

    elseif display_type == TRDTS.PERF then
        str = table.tostring(PERF_STATS)

    elseif display_type == TRDTS.SEED then
        str = "SEED: " .. HEX_MAP.seed

    elseif display_type == TRDTS.TILE then
        str = table.tostring(HEX_MAP.get(hex.x, hex.y))
    end
    return str
end

function main_action()
    if WIN:key_pressed"f1" then
        TRDT = (TRDT + 1) % #table.keys(TRDTS)
    end
end

function main_scene()
    return am.group():action(main_action)
end

game_init()
noglobals()

