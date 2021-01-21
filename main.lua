

math.randomseed(os.time())
math.random()
math.random()
math.random()

-- assets/non-or-trivial code
require "color"
require "sound"
require "texture"

require "src/entity"
require "src/extra"
require "src/geometry"
require "src/hexyz"
require "src/grid"
require "src/mob"
require "src/projectile"
require "src/tower"


-- Globals
WIN = am.window{
    width       = 1920,
    height      = 1080,
    title       = "hexyz",
    highdpi     = true,
    letterbox   = true,
    clear_color = color_at(0)
}

OFF_SCREEN = vec2(WIN.width * 2) -- arbitrary pixel position that is garunteed to be off screen
PERF_STATS = false               -- result of am.perf_stats() -- should be called every frame

WORLD = false -- root scene node of everything considered to be in the game world
              -- aka non gui stuff

TIME           = 0                  -- runtime of the current game in seconds (not whole program runtime)
SCORE          = 0                  -- score of the player
STARTING_MONEY = 50
MONEY          = STARTING_MONEY     -- available resources
MOUSE          = false              -- position of the mouse at the start of every frame, if an action is tracking it

-- global audio settings
MUSIC_VOLUME = 0.1
SFX_VOLUME   = 0.1

-- game stuff
SELECTED_TOWER_TYPE = TOWER_TYPE.REDEYE

-- top right display types
local TRDTS = {
    NOTHING        = -1,
    CENTERED_EVENQ = 0,
    EVENQ          = 1,
    HEX            = 2,
    PLATFORM       = 3,
    PERF           = 4,
    SEED           = 5,
    TILE           = 6
}
local TRDT = TRDTS.SEED

local function select_hex(hex)
    local tower = tower_on_hex(hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    log(tile)
end

local function can_do_build(hex, tile, tower_type)
    return can_afford_tower(MONEY, tower_type) and tower_is_buildable_on(hex, tile, tower_type)
end

local function game_action(scene)
    --if SCORE < 0 then game_end() end

    TIME       = TIME + am.delta_time
    SCORE      = SCORE + am.delta_time
    MOUSE      = WIN:mouse_position()
    PERF_STATS = am.perf_stats()

    local hex            = pixel_to_hex(MOUSE - WORLDSPACE_COORDINATE_OFFSET)
    local rounded_mouse  = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    local evenq          = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))
    local tile = HEX_MAP.get(hex.x, hex.y)
    local hot = evenq_is_interactable(evenq{ y = -evenq.y })

    do_entity_updates()
    do_mob_spawning()

    if WIN:mouse_pressed"left" then
        if hot and can_do_build(hex, tile, SELECTED_TOWER_TYPE) then
            build_tower(hex, SELECTED_TOWER_TYPE)
        end
    end

    if WIN:mouse_pressed"middle" then
        WIN.scene"scale".scale2d = vec2(1)
    else
        local mwd = vec2(WIN:mouse_wheel_delta().y / 1000)
        WIN.scene"scale".scale2d = WIN.scene"scale".scale2d + mwd
        WIN.scene"scale".scale2d = WIN.scene"scale".scale2d + mwd
    end

    if WIN:key_pressed"escape" then
        WIN.scene"game".paused = true
        WIN.scene:action(function()
            if WIN:key_pressed"escape" then
                WIN.scene"game".paused = false
                return true
            end
        end)
        --game_end()

    elseif WIN:key_pressed"f1" then
        TRDT = (TRDT + 1) % #table.keys(TRDTS)

    elseif WIN:key_pressed"tab" then
        local num_of_types = #table.keys(TOWER_TYPE)
        if WIN:key_down"lshift" then
            select_tower_type((SELECTED_TOWER_TYPE + num_of_types - 2) % num_of_types + 1)
        else
            select_tower_type((SELECTED_TOWER_TYPE) % num_of_types + 1)
        end

    elseif WIN:key_pressed"1" then select_tower_type(TOWER_TYPE.REDEYE)
    elseif WIN:key_pressed"2" then select_tower_type(2)
    elseif WIN:key_pressed"3" then select_tower_type(3)
    elseif WIN:key_pressed"4" then --select_tower_type(4)
    elseif WIN:key_pressed"5" then --select_tower_type(5)
    elseif WIN:key_pressed"6" then --select_tower_type(6)
    elseif WIN:key_pressed"7" then --select_tower_type(7)
    elseif WIN:key_pressed"8" then --select_tower_type(8)
    elseif WIN:key_pressed"9" then --select_tower_type(9)
    elseif WIN:key_pressed"0" then --select_tower_type(10)
    elseif WIN:key_pressed"-" then --select_tower_type(1)
    elseif WIN:key_pressed"=" then --select_tower_type(1)
    end

    if tile and hot then
        WIN.scene"hex_cursor".center = rounded_mouse
    else
        WIN.scene"hex_cursor".center = OFF_SCREEN
    end

    WIN.scene"score".text = string.format("SCORE: %.2f", SCORE)
    WIN.scene"money".text = string.format("MONEY: %d", MONEY)

    do
        local str = ""
        if TRDT == TRDTS.CENTERED_EVENQ then
            str = centered_evenq.x .. "," .. centered_evenq.y .. " (cevenq)"

        elseif TRDT == TRDTS.EVENQ then
            str = evenq.x .. "," .. evenq.y .. " (evenq)"

        elseif TRDT == TRDTS.HEX then
            str = hex.x .. "," .. hex.y .. " (hex)"

        elseif TRDT == TRDTS.PLATFORM then
            str = string.format("%s %s lang %s", am.platform, am.version, am.language())

        elseif TRDT == TRDTS.PERF then
            str = table.tostring(PERF_STATS)

        elseif TRDT == TRDTS.SEED then
            str = "SEED: " .. HEX_MAP.seed

        elseif TRDT == TRDTS.TILE then
            str = table.tostring(HEX_MAP.get(hex.x, hex.y))
        end
        WIN.scene"coords".text = str
    end

    --do_day_night_cycle()
end

function do_day_night_cycle()
    local slow = 100
    local tstep = (math.sin(TIME / 100) + 1) / PERF_STATS.avg_fps
    WORLD"negative_mask".color = vec4(tstep){a=1}
end

function game_end()
    -- de-initialize stuff
    delete_all_entities()
    TIME = 0
    SCORE = 0
    MONEY = STARTING_MONEY
    WORLD = false

    WIN.scene = am.group(am.scale(1) ^ game_scene())
end

function update_score(diff)
    SCORE = SCORE + diff
end

function update_money(diff)
    MONEY = MONEY + diff
end

local function toolbelt()
    local toolbelt_height = hex_height(HEX_SIZE) * 2
    local tower_tooltip = am.translate(WIN.left + 10, WIN.bottom + toolbelt_height + 20)
                          ^ am.text(tower_type_tostring(SELECTED_TOWER_TYPE), "left"):tag"tower_tooltip"
    local toolbelt = am.group{
        tower_tooltip,
        am.rect(WIN.left, WIN.bottom, WIN.right, WIN.bottom + toolbelt_height, COLORS.TRANSPARENT)
    }:tag"toolbelt"

    local padding = 15
    local size = toolbelt_height - padding
    local half_size = size/2
    local offset = vec2(WIN.left + padding*3, WIN.bottom + padding/3)

    local tab_button = am.translate(vec2(0, half_size) + offset)
                       ^ am.group{
                           pack_texture_into_sprite(TEX_WIDER_BUTTON1, 54, 32),
                           pack_texture_into_sprite(TEX_TAB_ICON, 25, 25)
                       }
    toolbelt:append(tab_button)

    local tower_select_square = (
        am.translate(vec2(size + padding, half_size) + offset)
        ^ am.rect(-size/2-3, -size/2-3, size/2+3, size/2+3, COLORS.SUNRAY)
    ):tag"tower_select_square"
    toolbelt:append(tower_select_square)

    local tower_type_values = table.values(TOWER_TYPE)
    local keys = { '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=' }
    for i = 1, #keys do
        if tower_type_values[i] then
            toolbelt:append(
                am.translate(vec2(size + padding, 0) * i + offset)
                ^ am.group{
                    am.translate(0, half_size)
                    ^ pack_texture_into_sprite(TEX_BUTTON1, size, size),

                    am.translate(0, half_size)
                    ^ pack_texture_into_sprite(get_tower_texture(tower_type_values[i]), size, size),

                    am.translate(vec2(half_size))
                    ^ am.group{
                        pack_texture_into_sprite(TEX_BUTTON1, half_size, half_size),
                        am.scale(2)
                        ^ am.text(keys[i], COLORS.BLACK)
                    }
                }
            )
        else
            toolbelt:append(
                am.translate(vec2(size + padding, 0) * i + offset)
                ^ am.group{
                    am.translate(0, half_size)
                    ^ pack_texture_into_sprite(TEX_BUTTON1, size, size),

                    am.translate(vec2(half_size))
                    ^ am.group{
                        pack_texture_into_sprite(TEX_BUTTON1, half_size, half_size),
                        am.scale(2)
                        ^ am.text(keys[i], COLORS.BLACK)
                    }
                }
            )
        end
    end

    select_tower_type = function(tower_type)
        SELECTED_TOWER_TYPE = tower_type
        WIN.scene"tower_tooltip".text = tower_type_tostring(tower_type)

        local new_position = vec2((size + padding) * tower_type, size/2) + offset
        WIN.scene"tower_select_square":action(am.tween(0.1, { position2d = new_position }))

        WIN.scene:action(am.play(am.sfxr_synth(SOUNDS.SELECT1), false, 1, SFX_VOLUME))
    end

    return toolbelt
end

-- @NOTE must be global to allow the game_action to reference it
function game_scene()
    local score = am.translate(WIN.left + 10, WIN.top - 20) ^ am.text("", "left"):tag"score"
    local money = am.translate(WIN.left + 10, WIN.top - 40) ^ am.text("", "left"):tag"money"
    local coords = am.translate(WIN.right - 10, WIN.top - 20) ^ am.text("", "right", "top"):tag"coords"
    local hex_cursor = am.circle(OFF_SCREEN, HEX_SIZE, COLORS.TRANSPARENT, 6):tag"hex_cursor"

    local curtain = am.rect(WIN.left, WIN.bottom, WIN.right, WIN.top, COLORS.TRUE_BLACK)
    curtain:action(coroutine.create(function()
        am.wait(am.tween(curtain, 3, { color = vec4(0) }, am.ease.out(am.ease.hyperbola)))
        WIN.scene:remove(curtain)
    end))

    -- 2227
    HEX_MAP, WORLD = random_map()

    local scene = am.group{
        WORLD,
        curtain,
        hex_cursor,
        toolbelt(),
        score,
        money,
        coords,
    }:tag"game"

    scene:action(game_action)
    --scene:action(am.play(SOUNDS.TRACK1))

    return scene
end

load_textures()
WIN.scene = am.group(am.scale(vec2(1)) ^ game_scene())
noglobals()

