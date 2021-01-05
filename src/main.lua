

math.randomseed(os.time()); math.random(); math.random(); math.random()
--============================================================================
-- Imports
require "color"
require "grid"
require "mob"
require "tower"


--============================================================================
-- Globals
win = am.window{ width = 1920, height = 1080 }

TIME = 0
SCORE = 0

local COORDINATE_DISPLAY_TYPES = {
    CENTERED_EVENQ  = 0,
    EVENQ           = 1,
    HEX             = 2
}

local COORDINATE_DISPLAY_TYPE = COORDINATE_DISPLAY_TYPES.CENTERED_EVENQ

function game_action(scene)
    TIME = am.current_time()
    SCORE = TIME

    local mouse = win:mouse_position()
    local hex = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET)
    local evenq = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))

    local tile = HEX_MAP.get(hex.x, hex.y)

    if win:mouse_pressed"left" then
    end

    if win:key_pressed"f3" then
        COORDINATE_DISPLAY_TYPE = (COORDINATE_DISPLAY_TYPE + 1) % #table.keys(COORDINATE_DISPLAY_TYPES)
    end

    do_mob_updates()
    do_mob_spawning()

    if tile and is_interactable(tile, evenq{ y = -evenq.y }) then
        win.scene"hex_cursor".center = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    else
        win.scene"hex_cursor".center = vec2(6969)
    end

    win.scene"score".text = string.format("SCORE: %.2f", SCORE)

    do
        local str, coords
        if COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.CENTERED_EVENQ then
            str, coords = "evenqc: ", centered_evenq

        elseif COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.EVENQ then
            str, coords = "evenq: ", evenq

        elseif COORDINATE_DISPLAY_TYPE == COORDINATE_DISPLAY_TYPES.HEX then
            str, coords = "hex: ", hex
        end
        win.scene"coords".text = string.format("%s%d,%d", str, coords.x, coords.y)
    end
end

function game_scene()
    local score = am.translate(win.left + 10, win.top - 20) ^ am.text("", "left"):tag"score"
    local coords = am.translate(win.right - 10, win.top - 20) ^ am.text("", "right"):tag"coords"
    local hex_cursor = am.circle(vec2(-6969), HEX_SIZE, COLORS.TRANSPARENT, 6):tag"hex_cursor"

    local curtain = am.rect(win.left, win.bottom, win.right, win.top, COLORS.TRUEBLACK)
    curtain:action(coroutine.create(function()
        am.wait(am.tween(curtain, 3, { color = vec4(0) }, am.ease.out(am.ease.hyperbola)))
        win.scene:remove(curtain)
    end))

    local world
    HEX_MAP, world = random_map()

    local scene = am.group{
        world,
        curtain,
        hex_cursor,
        score,
        coords
    }

    scene:action(game_action)

    return scene
end

function init()
    require "texture"
    load_textures()
    win.scene = am.scale(1) ^ game_scene()
end

init()
noglobals()

