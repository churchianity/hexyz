

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
    self"hex_backdrop""rotate".angle = math.wrapf(self"hex_backdrop""rotate".angle - 0.005 * am.delta_time, math.pi*2)
end

function make_main_scene_toolbelt()
    local options = {
        false,
        false,
        false,
        false,
        {
            texture = TEXTURES.NEW_GAME_HEX,
            action = function() game_init() end
        },
        {
            texture = TEXTURES.LOAD_GAME_HEX,
            action = function() game_init(am.load_state("save", "json")) end
        },
        false,
        {
            texture = TEXTURES.SETTINGS_HEX,
            action = function() end
        },
        {
            texture = TEXTURES.ABOUT_HEX,
            action = function() end
        },
        false,
        false,
        false,
        {
            texture = TEXTURES.MAP_EDITOR_HEX,
            action = function() log("map editor not implemented") end
        },
        false
    }

    local spacing = 160

    -- calculate the dimensions of the whole grid
    local grid_width = 10
    local grid_height = 2
    local hhs = hex_horizontal_spacing(spacing)
    local hvs = hex_vertical_spacing(spacing)
    local grid_pixel_width = grid_width * hhs
    local grid_pixel_height = grid_height * hvs
    local pixel_offset = vec2(-grid_pixel_width/2, win.bottom + hex_height(spacing)/2 + 20)

    local map = hex_rectangular_map(grid_width, grid_height, HEX_ORIENTATION.POINTY)
    local group = am.group()
    local option_index = 1
    for i,_ in pairs(map) do
        for j,_ in pairs(map[i]) do
            local hex = vec2(i, j)
            local position = hex_to_pixel(hex, vec2(spacing), HEX_ORIENTATION.POINTY)
            local option = options[option_index]
            local texture = option and option.texture or TEXTURES.SHADED_HEX
            local node = am.translate(position)
                         ^ pack_texture_into_sprite(texture, texture.width, texture.height, COLORS.TRANSPARENT)

            hex_map_set(map, i, j, {
                node = node,
                option = option
            })
            local tile = hex_map_get(map, i, j)

            node:action(function(self)
                local mouse = win:mouse_position()
                local hex_ = pixel_to_hex(mouse - pixel_offset, vec2(spacing), HEX_ORIENTATION.POINTY)

                if hex == hex_ and tile.option then
                    tile.node"sprite".color = vec4(1)

                    if win:mouse_pressed("left") then
                        tile.option.action()
                    end
                else
                    tile.node"sprite".color = COLORS.TRANSPARENT
                end
            end)

            group:append(node)
            option_index = option_index + 1
        end
    end

    return am.translate(pixel_offset) ^ group
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

    local logo_height = 480
    group:append(am.translate(0, win.top - 20 - logo_height/2) ^ am.sprite("res/logo.png"))

    group:append(make_main_scene_toolbelt())

    group:action(main_action)

    return group
end

win.scene = main_scene()
noglobals()

