

math.randomseed(os.time())
math.random()
math.random()
math.random()

require "color"
require "grid"
require "mob"
require "tower"

-- Globals
WIN = am.window{ width = 1920, height = 1080 }

TIME = 0
SCORE = 0
OFF_SCREEN = vec2(WIN.width * 2) -- random pixel position that is garunteed to be off screen

local COORDINATE_DISPLAY_TYPES = {
    CENTERED_EVENQ = 0,
    EVENQ          = 1,
    HEX            = 2
}

local COORDINATE_DISPLAY_TYPE = COORDINATE_DISPLAY_TYPES.CENTERED_EVENQ
local function game_action(scene)
    TIME = am.current_time()
    SCORE = TIME

    local mouse = WIN:mouse_position()
    local hex = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET)
    local rounded_mouse = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    local evenq = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))
    local tile = HEX_MAP.get(hex.x, hex.y)
    local hot = is_interactable(tile, evenq{ y = -evenq.y })

    if WIN:mouse_pressed"left" then
        if hot and is_buildable(hex, tile, nil) then
            make_tower(hex)
        end
    end

    if WIN:key_pressed"f3" then
        COORDINATE_DISPLAY_TYPE = (COORDINATE_DISPLAY_TYPE + 1) % #table.keys(COORDINATE_DISPLAY_TYPES)
    end

    do_tower_updates()
    do_mob_updates()
    do_mob_spawning()

    if tile and hot then
        WIN.scene"hex_cursor".center = rounded_mouse
    else
        WIN.scene"hex_cursor".center = OFF_SCREEN
    end

    WIN.scene"score".text = string.format("SCORE: %.2f", SCORE)

    do
        local str, coords
        if COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.CENTERED_EVENQ then
            str, coords = "evenqc", centered_evenq

        elseif COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.EVENQ then
            str, coords = "evenq", evenq

        elseif COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.HEX then
            str, coords = "hex", hex
        end
        WIN.scene"coords".text = string.format("%d,%d (%s)", coords.x, coords.y, str)
    end
end

local function toolbelt()
    local toolbelt_height = hex_height(HEX_SIZE) * 2
    local toolbelt = am.group{
        am.rect(WIN.left, WIN.bottom, WIN.right, WIN.bottom + toolbelt_height, COLORS.TRANSPARENT)
    }

    --[[
    local padding = 22
    local size = toolbelt_height - padding
    for i = 0, 0 do
        toolbelt:append(
            am.translate(vec2(size + padding, 0) * i + vec2(WIN.left + padding/3, WIN.bottom + padding/3))
            ^ am.rect(0, 0, size, size, COLORS.BLACK)
        )
    end
    ]]

    return toolbelt
end

local function game_scene()
    local score = am.translate(WIN.left + 10, WIN.top - 20) ^ am.text("", "left"):tag"score"
    local coords = am.translate(WIN.right - 10, WIN.top - 20) ^ am.text("", "right"):tag"coords"
    local hex_cursor = am.circle(OFF_SCREEN, HEX_SIZE, COLORS.TRANSPARENT, 6):tag"hex_cursor"

    local curtain = am.rect(WIN.left, WIN.bottom, WIN.right, WIN.top, COLORS.TRUE_BLACK)
    curtain:action(coroutine.create(function()
        am.wait(am.tween(curtain, 3, { color = vec4(0) }, am.ease.out(am.ease.hyperbola)))
        WIN.scene:remove(curtain)
    end))

    local world
    HEX_MAP, world = random_map()

    local scene = am.group{
        world,
        curtain,
        hex_cursor,
        toolbelt(),
        score,
        coords,
    }

    scene:action(game_action)

    return scene
end

local function init()
    require "texture"
    load_textures()
    WIN.scene = am.scale(1) ^ game_scene()
end

init()
noglobals()

