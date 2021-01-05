

math.randomseed(os.time()); math.random(); math.random(); math.random()
--============================================================================
-- Imports
require "color"
require "grid"
require "mob"
require "math"
require "table"


--============================================================================
-- Globals
TIME = 0

win = am.window{ width = 1920, height = 1080 }

function game_action(scene)
    TIME = am.current_time()

    local mouse = win:mouse_position()
    local hex = pixel_to_hex(mouse - WORLDSPACE_COORDINATE_OFFSET)
    local _off = hex_to_evenq(hex)
    local off = _off{ y = -_off.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                         , math.floor(HEX_GRID_HEIGHT/2))
    local tile = get_tile(hex.x, hex.y)

    if tile and win:mouse_pressed"left" then
    end

    if win:key_pressed"f1" then end

    do_mob_updates()
    do_mob_spawning()

    -- draw stuff
    win.scene"hex_cursor".center = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    win.scene"score".text = string.format("SCORE: %.2f", TIME)
    win.scene"coords".text = string.format("%d,%d", hex.x, hex.y)
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

