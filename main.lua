
-- all 4:3 aspect ratio
local RESOLUTION_OPTIONS = {
    { width = 1440, height = 1080 },
    { width = 1400, height = 1050 }, -- seems like a good default one
    { width = 1280, height = 960 },
    { width = 1152, height = 864 },
    { width = 1024, height = 768 },
    { width = 960, height = 720 },
    { width = 832, height = 624 },
    { width = 800, height = 600 },
}
local DEFAULT_RESOLUTION = RESOLUTION_OPTIONS[2]

SETTINGS = am.load_state("settings", "json") or {
    fullscreen = false,
    window_width = DEFAULT_RESOLUTION.width,
    window_height = DEFAULT_RESOLUTION.height,
    music_volume = 0.2,
    sfx_volume = 0.1,
    sound_on = true
}

win = am.window{
    width     = SETTINGS.window_width,
    height    = SETTINGS.window_height,
    title     = "",
    mode      = SETTINGS.fullscreen and "fullscreen" or "windowed",
    resizable = false,
    highdpi   = true,
    letterbox = true,
    show_cursor = true,
    clear_color = vec4(0),
}

-- top right display types
-- different scenes overlay different content in the top right of the screen
-- f1 toggles what is displayed in the top right of the screen in some scenes
TRDTS = {
    NOTHING        = 0,
    CENTERED_EVENQ = 1,
    EVENQ          = 2,
    HEX            = 3,
    PLATFORM       = 4,
    PERF           = 5,
    SEED           = 6,
    TILE           = 7,
}

function make_top_right_display_node()
    return am.translate(win.right - 10, win.top - 15)
           ^ am.text("", "right", "top"):tag"top_right_display"
end

require "conf"

-- library/standard code (ours)
require "lib/random"
require "lib/extra"
require "lib/memory"
require "lib/geometry"
require "lib/gui"
require "lib/color"
require "lib/sound"
require "lib/texture"

-- other internal dependencies
require "src/hexyz"
require "src/grid"
require "src/game"
require "src/tower"
require "src/mob"
require "src/map-editor"
require "src/entity"
require "src/projectile"

function main_action(self)
    if win:key_pressed("escape") then
        if game then
            unpause(self)
        else
            --win:close()
        end
    elseif win:key_pressed("f4") then
        win:close()

    elseif win:key_pressed("m") then
        toggle_mute()
    end

    if self"hex_backdrop" then
        self"hex_backdrop""rotate".angle = math.wrapf(self"hex_backdrop""rotate".angle - 0.005 * am.delta_time, math.pi*2)
    end
end

function main_scene(do_backdrop, do_logo)
    local group = am.group()

    if do_backdrop then
        local map = hex_hexagonal_map(30)
        local hex_backdrop = (am.rotate(0) ^ am.group()):tag"hex_backdrop"
        for i,_ in pairs(map) do
            for j,n in pairs(map[i]) do
                local color = map_elevation_to_color(n)
                color = color{a=color.a - 0.1}

                local node = am.translate(hex_to_pixel(vec2(i, j), vec2(HEX_SIZE)))
                             ^ am.circle(vec2(0), HEX_SIZE, vec4(0), 6)

                node"circle":action(am.tween(0.6, { color = color }))

                hex_backdrop:append(node)
            end
        end
        group:append(hex_backdrop)

    else
        group:append(
            pack_texture_into_sprite(TEXTURES.CURTAIN, win.width, win.height)
        )
    end

    -- version/author info
    group:append(
        am.translate(win.right - 10, win.bottom + 10)
        ^ am.text(string.format("v%s, by %s", version, author), COLORS.WHITE, "right", "bottom")
    )

    if do_logo then
        local position = vec2(0, win.top - 20 - TEXTURES.LOGO.height/2)
        local logo =
            am.translate(position)
            ^ pack_texture_into_sprite(TEXTURES.LOGO, TEXTURES.LOGO.width, TEXTURES.LOGO.height)

        local selected = false
        logo:action(function(self)
            local mouse = win:mouse_position()
            if math.distance(mouse, position) < TEXTURES.LOGO.height/2 then
                selected = true
                self"sprite".color = vec4(1)
                if win:mouse_pressed("left") then
                    vplay_sfx(math.random(1000000000))
                end
            else
                selected = false
                self"sprite".color = vec4(0.95)
            end
        end)

        group:append(logo)
    end

    local seed_textfield, get_seed_textfield_value = gui_make_textfield{
        position = vec2(win.left + 500, 50),
        dimensions = vec2(90, 40),
        max = math.ceil(math.log(HEX_GRID_WIDTH * HEX_GRID_HEIGHT, 10)),
        validate = function(string)
            return not string.match(string, "%D")
        end,
    }
    group:append(
        seed_textfield
    )
    group:append(
        am.translate(win.left + 220, 50) ^ pack_texture_into_sprite(TEXTURES.SEED_COLON_TEXT)
    )

    local main_scene_options = {
        false,
        {
            texture = TEXTURES.NEW_GAME_HEX,
            action = function()
                game_init(nil, tonumber(get_seed_textfield_value()))
            end
        },
        false,
        false,
        false,
        {
            texture = TEXTURES.LOAD_GAME_HEX,
            action = function()
                local save = am.load_state("save", "json")

                if save then
                    game_init(save)
                else
                    gui_alert("no saved games")
                end
            end
        },
        {
            texture = TEXTURES.MAP_EDITOR_HEX,
            action = function()
                map_editor_init()
            end
        },
        false,
        {
            texture = TEXTURES.SETTINGS_HEX,
            action = function()
                gui_alert("not yet :)")
            end
        },
        {
            texture = TEXTURES.QUIT_HEX,
            action = function()
                win:close()
            end
        },
        false
    }

    group:append(make_scene_menu(main_scene_options, "main_menu"))

    group:action(main_action)
    return group
end

function make_scene_menu(scene_options, tag, do_curtain)
    -- calculate the dimensions of the whole grid
    local spacing = 150
    local grid_width = 6
    local grid_height = 2
    local hhs = hex_horizontal_spacing(spacing)
    local hvs = hex_vertical_spacing(spacing)
    local grid_pixel_width = grid_width * hhs
    local grid_pixel_height = grid_height * hvs
    local pixel_offset = vec2(-grid_pixel_width/2, win.bottom + hex_height(spacing)/2 + 20)

    -- generate a map of hexagons (the menu is made up of two rows of hexes) and populate their locations with buttons from the provided options
    local map = hex_rectangular_map(grid_width, grid_height, HEX_ORIENTATION.POINTY)
    local group = am.group():tag(tag or "menu")
    if do_curtain then
        group:append(pack_texture_into_sprite(TEXTURES.CURTAIN, win.width, win.height))
    end

    local menu = am.group()
    local option_index = 1
    for i,_ in pairs(map) do
        for j,_ in pairs(map[i]) do
            local hex = vec2(i, j)
            local position = hex_to_pixel(hex, vec2(spacing), HEX_ORIENTATION.POINTY)
            local option = scene_options[option_index]
            local texture = option and option.texture or TEXTURES.SHADED_HEX
            local color = option and COLORS.TRANSPARENT3 or vec4(0.3)
            local node = am.translate(position)
                         ^ pack_texture_into_sprite(texture, texture.width, texture.height, color)

            hex_map_set(map, i, j, {
                node = node,
                option = option
            })
            local tile = hex_map_get(map, i, j)

            local selected = false
            node:action(function(self)
                local mouse = win:mouse_position()
                local hex_ = pixel_to_hex(mouse - pixel_offset, vec2(spacing), HEX_ORIENTATION.POINTY)

                if tile.option then
                    if tile.option.keys and tile.option.action then

                        for _,key in pairs(win:keys_pressed()) do
                            if table.find(tile.option.keys, function(_key) return _key == key end) then
                                tile.option.action()
                            end
                        end
                    end
                    if hex == hex_ then
                        if not selected then
                            play_sfx(SOUNDS.SELECT1)
                        end
                        selected = true
                        tile.node"sprite".color = vec4(1)

                        if win:mouse_pressed("left") then
                            tile.option.action()
                        end
                    else
                        selected = false
                        tile.node"sprite".color = COLORS.TRANSPARENT3
                    end
                end
            end)

            menu:append(node)
            option_index = option_index + 1
        end
    end
    group:append(am.translate(pixel_offset) ^ menu)

    return group
end

function switch_context(scene, action)
    win.scene:remove("menu")

    if action then
        win.scene:replace("context", scene:action(action):tag"context")
    else
        win.scene:replace("context", scene:tag"context")
    end
end

function init()
    init_entity_specs()
    switch_context(main_scene(true, true))
end

win.scene = am.group(am.group():tag"context")
init()
noglobals()

