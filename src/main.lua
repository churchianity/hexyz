

math.randomseed(os.time())
math.random()
math.random()
math.random()

require "color"
require "entity"
require "grid"
require "mob"
require "projectile"
require "tower"

-- Globals
WIN = am.window{
    width       = 1920,
    height      = 1080,
    title       = "hexyz",
    resizable   = false
}

OFF_SCREEN = vec2(WIN.width * 2) -- arbitrary pixel position that is garunteed to be off screen

WORLD = false -- root scene node of everything considered to be in the game world
TIME  = 0     -- runtime of the current game in seconds
SCORE = 0     -- score of the player
MONEY = 0     -- available resources
MOUSE = false -- position of the mouse at the start of every frame, if an action is tracking it
RAND  = 0     -- result of first call to math.random() this frame

-- global audio settings
MUSIC_VOLUME = 0.1
SFX_VOLUME   = 0.1

local TRDTS = {
    NOTHING        = -1,
    CENTERED_EVENQ = 0,
    EVENQ          = 1,
    HEX            = 2,
    PLATFORM       = 3,
    PERF           = 4
}

local TRDT = TRDTS.CENTERED_EVENQ
local function game_action(scene)
    if SCORE < 0 then game_end() end

    TIME  = am.current_time()
    SCORE = SCORE + am.delta_time
    RAND  = math.random()
    MOUSE = WIN:mouse_position()

    local hex            = pixel_to_hex(MOUSE - WORLDSPACE_COORDINATE_OFFSET)
    local rounded_mouse  = hex_to_pixel(hex) + WORLDSPACE_COORDINATE_OFFSET
    local evenq          = hex_to_evenq(hex)
    local centered_evenq = evenq{ y = -evenq.y } - vec2(math.floor(HEX_GRID_WIDTH/2)
                                                      , math.floor(HEX_GRID_HEIGHT/2))
    local tile = HEX_MAP.get(hex.x, hex.y)
    local hot = is_interactable(tile, evenq{ y = -evenq.y })

    do_entity_updates()
    do_mob_spawning()

    if WIN:mouse_pressed"left" then
        if hot and is_buildable(hex, tile, nil) then
            make_and_register_tower(hex)
        end
    end

    if WIN:key_pressed"escape" then
        pause()

    elseif WIN:key_pressed"f2" then
        WIN.scene = game_scene()

    elseif WIN:key_pressed"f3" then
        TRDT = (TRDT + 1) % #table.keys(TRDTS)

    elseif WIN:key_pressed"f4" then
        log(HEX_MAP.seed)
        print(HEX_MAP.seed)
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
            str = string.format("%d,%d (cevenq)", centered_evenq.x, centered_evenq.y)

        elseif TRDT == TRDTS.EVENQ then
            str = string.format("%d,%d (evenq)", evenq.x, evenq.y)

        elseif TRDT == TRDTS.HEX then
            str = string.format("%d,%d (hex)", hex.x, hex.y)

        elseif TRDT == TRDTS.PLATFORM then
            str = string.format("%s %s lang %s", am.platform, am.version, am.language())

        elseif TRDT == TRDTS.PERF then
            str = table.tostring(am.perf_stats())
        end
        WIN.scene"coords".text = str
    end
end

function pause()
    WORLD"group".paused = true
end

function game_end()
    WIN.scene.paused = true

    -- de-initialize stuff
    delete_all_entities()
    SCORE = 0

    WIN.scene = game_scene()
end

function update_score(diff)
    SCORE = SCORE + diff
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

    HEX_MAP, WORLD = random_map()

    local scene = am.group{
        WORLD,
        curtain,
        hex_cursor,
        toolbelt(),
        score,
        money,
        coords,
    }

    scene:action(game_action)
    scene:action(am.play(SOUNDS.TRACK1))

    return scene
end

function get_debug_string()

end

require "texture"
load_textures()
WIN.scene = am.scale(1) ^ game_scene()
noglobals()

