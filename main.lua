-- @TODO
-- main
--      -- scale menu hexes to window size, right now they look bad on smaller resolutions

-- settings menu
--      -- make the volume icon clickable
--      -- music volume slider or number input box
--      -- sfx volume slider or number input box
--      -- allow different resolution options, as long as you are 4:3

-- serialization
--      -- allow saving by name
--      -- allow loading by name
--      -- investigate saving as lua instead, and having as a consequence a less janky map serialization - we don't care about exploitability

-- sound
--      -- fix the non-seamless loop in the soundtrack
--      -- more trax

-- game
--      -- allow selecting of tiles, if tower is selected then allow sell/upgrade
--      -- new game menu allowing set seed
--      -- make art, birds-eye-ify the redeye tower and lighthouse maybe?

-- map editor?
--      -- paint terrain elevation levels
--      -- place tiles of set elevation
--      -- place towers
--      -- move home?

-- lua's random number generator doesn't really produce random looking values if you don't seed it and discard a few calls first
math.randomseed(os.time())
math.random()
math.random()
math.random()
math.random()

-- aspect ratios seem like a huge mess
-- for now, i think we should enforce 4:3
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

settings = am.load_state("settings", "json") or {
    fullscreen = false,
    window_width = DEFAULT_RESOLUTION.width,
    window_height = DEFAULT_RESOLUTION.height,
    music_volume = 0.2,
    sfx_volume = 0.1,
    sound_on = true
}

win = am.window{
    width     = settings.window_width,
    height    = settings.window_height,
    title     = "hexyz",
    mode      = settings.fullscreen and "fullscreen" or "windowed",
    resizable = false,
    highdpi   = true,
    letterbox = true,
    show_cursor = true,
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

-- asset interfaces and/or trivial code
require "conf"
require "color"
require "sound"
require "texture"

--
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
require "src/map-editor"


local sound_toggle_node_tag = "sound_on_off_icon"
local function make_sound_toggle_node(on)
    local sprite
    if on then
        sprite = pack_texture_into_sprite(TEXTURES.SOUND_ON1, 40, 30)
    else
        sprite = pack_texture_into_sprite(TEXTURES.SOUND_OFF, 40, 30)
    end

    return (am.translate(win.right - 30, win.top - 60) ^ sprite)
    :tag(sound_toggle_node_tag)
    :action(function()
        -- @TODO click me!
    end)
end

local cached_music_volume = 0.2
local cached_sfx_volume = 0.1
local function toggle_mute()
    settings.sound_on = not settings.sound_on

    if settings.sound_on then
        settings.music_volume = cached_music_volume
        settings.sfx_volume = cached_sfx_volume
    else
        cached_music_volume = settings.music_volume
        cached_sfx_volume = settings.sfx_volume

        settings.music_volume = 0
        settings.sfx_volume = 0
    end

    update_music_volume(settings.music_volume)

    win.scene:replace(sound_toggle_node_tag, make_sound_toggle_node(settings.sound_on))
end

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

function make_scene_menu(scene_options)

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
    local group = am.group()
    local option_index = 1
    for i,_ in pairs(map) do
        for j,_ in pairs(map[i]) do
            local hex = vec2(i, j)
            local position = hex_to_pixel(hex, vec2(spacing), HEX_ORIENTATION.POINTY)
            local option = scene_options[option_index]
            local texture = option and option.texture or TEXTURES.SHADED_HEX
            local color = option and COLORS.TRANSPARENT or vec4(0.3)
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
                        tile.node"sprite".color = COLORS.TRANSPARENT
                    end
                end
            end)

            group:append(node)
            option_index = option_index + 1
        end
    end

    return am.translate(pixel_offset) ^ group
end

function main_scene(do_backdrop, do_logo)
    local group = am.group()

    if do_backdrop then
        local map = hex_hexagonal_map(30)
        local hex_backdrop = (am.rotate(0) ^ am.group()):tag"hex_backdrop"
        for i,_ in pairs(map) do
            for j,n in pairs(map[i]) do
                local color = map_elevation_color(n)
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

    group:append(
        make_sound_toggle_node(settings.sound_on)
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

    local main_scene_options = {
        false,
        {
            texture = TEXTURES.NEW_GAME_HEX,
            action = function()
                win.scene:remove"map_editor"
                win.scene:remove"menu"
                game_init()
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
                    win.scene:remove("menu")
                    game_init(save)
                else
                    gui_alert("no saved games")
                end
            end
        },
        {
            texture = TEXTURES.MAP_EDITOR_HEX,
            action = function()
                win.scene:remove("menu")
                map_editor_init()
            end
        },
        false,
        {
            texture = TEXTURES.SETTINGS_HEX,
            action = function() gui_alert("not yet :)") end
        },
        {
            texture = TEXTURES.QUIT_HEX,
            action = function() win:close() end
        },
        false
    }

    group:append(make_scene_menu(main_scene_options))

    group:action(main_action)

    return group:tag"menu"
end

win.scene = am.group(
    main_scene(true, true)
)
play_track(SOUNDS.MAIN_THEME)

noglobals()

