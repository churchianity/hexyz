
-- @TODO @TODO @TODO @TODO @TODO
-- settings menu
--      -- music volume
--      -- sfx volume
--      -- resolution settings & fix grid size being based on resolution
--
-- serialization
--      -- allow saving by name
--      -- allow loading by name
--      -- investigate saving as lua instead, and having as a consequence a less janky map serialization
--      -- encode/decode save game data (low priority)
--
-- map editor
--      -- paint terrain elevation levels
--      -- place tiles of set elevation
--      -- place towers
--      -- move home?
--
-- game
--      -- HEX_GRID_CENTER =/= HOME
--      -- allow selecting of tiles, if tower is selected then allow sell/upgrade
--      -- button/ui to open pause menu - make it obvious that 'esc' is the button
--      -- play the game and tweak numbers
--      -- new game menu allowing set seed
--      -- gattling gun tower (fast fire rate)
--      -- spooder mob
--      -- make art, birds-eye-ify the redeye tower and lighthouse maybe?


-- aspect ratios seem like a huge mess
-- for now, i think we should enforce 4:3
local RESOLUTION_OPTIONS = {
    -- 16:9
    -- { width = 1776, height = 1000 },
    -- { width = 1920, height = 1080 },
    -- { width = 1600, height = 900 },

    -- 4:3
    { width = 1440, height = 1080 },
    { width = 1400, height = 1050 }, -- seems like a good one
    { width = 1280, height = 960 },
    { width = 1152, height = 864 },
    { width = 1024, height = 768 },
    { width = 960, height = 720 },
    { width = 832, height = 624 },
    { width = 800, height = 600 },
}

settings = am.load_state("settings", "json") or {
    fullscreen = false,
    window_width = 1400,
    window_height = 1050,
    music_volume = 0.2,
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
        resizable = true,
        highdpi   = true,
        resizable = true, -- user should probably set their resolution instead of resizing the window, but hey.
        letterbox = true,
        show_cursor = true,
    }
end

-- asset interfaces and/or trivial code
require "conf"
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


-- text popup in the middle of the screen that dissapates, call from anywhere
function alert(message, color)
    win.scene:append(
        am.scale(3) ^ am.text(message, color or COLORS.WHITE)
        :action(coroutine.create(function(self)
            am.wait(am.tween(self, 1, { color = vec4(0) }, am.ease_out))
            win.scene:remove(self)
        end))
    )
end

function unpause(root_node)
    win.scene("game").paused = false
    win.scene:remove(root_node)
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
    end
    if self"hex_backdrop" then
        self"hex_backdrop""rotate".angle = math.wrapf(self"hex_backdrop""rotate".angle - 0.005 * am.delta_time, math.pi*2)
    end
end

function make_main_scene_toolbelt()
    local include_save_option = game
    local include_unpause_option = game
    local options = {
        false,
        {
            texture = TEXTURES.NEW_GAME_HEX,
            action = function()
                win.scene:remove"menu"
                game_init()
            end
        },
        false,
        include_save_option and {
            texture = TEXTURES.SAVE_GAME_HEX,
            action = function()
                game_save()
                alert("succesfully saved!")
            end
        } or false,
        false,
        {
            texture = TEXTURES.LOAD_GAME_HEX,
            action = function()
                local save = am.load_state("save", "json")

                if save then
                    win.scene:remove("menu")
                    game_init(save)
                else
                    alert("no saved games")
                end
            end
        },
        {
            texture = TEXTURES.MAP_EDITOR_HEX,
            action = function() alert("not yet :)") end
        },
        include_unpause_option and {
            texture = TEXTURES.UNPAUSE_HEX,
            action = function() unpause(win.scene("menu")) end
        } or false,
        {
            texture = TEXTURES.SETTINGS_HEX,
            action = function() alert("not yet :)") end
        },
        {
            texture = TEXTURES.QUIT_HEX,
            action = function() win:close() end
        },
        false
    }

    -- calculate the dimensions of the whole grid
    local spacing = 150
    local grid_width = 6
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

    -- @TODO add a hyperlink to an 'about' page or something
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

                end
            else
                selected = false
                self"sprite".color = vec4(0.95)
            end
        end)

        group:append(logo)
    end

    group:append(make_main_scene_toolbelt())

    group:action(main_action)

    return group:tag"menu"
end

win.scene = am.group(
    main_scene(true, true)
)
play_track(SOUNDS.MAIN_THEME)

noglobals()

