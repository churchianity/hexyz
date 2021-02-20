

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

-- asset interfaces and/or trivial code
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


function main_action(self)
    self"hex_backdrop""rotate".angle = math.wrapf(self"hex_backdrop""rotate".angle - 0.002 * am.delta_time, math.pi*2)
end

function make_main_scene_toolbelt()
    local options = {
        {
            label = "new game",
            action = function(self) end
        },
        {
            label = "load game",
            action = function(self) game_init(am.load_state("save", "json")) end
        },
        {
            label = "map editor",
            action = function(self) log("map editor not implemented") end
        },
        {
            label = "settings",
            action = function(self) end
        },
    }
    --local map = hex_rectangular_map(10, 20, HEX_ORIENTATION.POINTY)

    return group
end

function main_scene()
    local group = am.group()

    local map = hex_hexagonal_map(30)
    local hex_backdrop = (am.rotate(0) ^ am.group()):tag"hex_backdrop"
    for i,_ in pairs(map) do
        for j,n in pairs(map[i]) do
            local color = map_elevation_color(n)
            color = color{a=color.a - 0.1}

            local node = am.translate(hex_to_pixel(vec2(i, j), vec2(HEX_SIZE)))
                         ^ am.circle(vec2(0), HEX_SIZE, vec4(0), 6)

            node"circle":action(am.tween(1, { color = color }))

            hex_backdrop:append(node)
        end
    end
    group:append(hex_backdrop)

    group:append(am.translate(0, 200) ^ am.sprite("res/logo.png"))
    group:append(make_main_scene_toolbelt())

    group:action(main_action)

    return group
end

win.scene = am.group()
game_init()
noglobals()

