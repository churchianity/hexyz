
math.randomseed(os.time()); math.random(); math.random(); math.random()
--[[=I==========================================================================]]
-- Imports
require "hexyz"
require "grid"


--[[============================================================================]]
-- Globals

win = am.window{
    width = 1920,
    height = 1080,
    resizable = false
}
--[[============================================================================]]
-- Local 'Globals'

local home


function poll_mouse()
    if win:mouse_position().x > -268 then -- mouse is inside game map

        local hex = pixel_to_hex(win:mouse_position() - vec2(-278, -318))
        local off = hex_to_offset(hex)

        -- check if cursor location outside of map bounds
        if off.x <= 1 or -off.y <= 1 or off.x >= 46 or -off.y >= 32 then
            win.scene"coords".text = ""

        else
            if win:mouse_down"left" then
                if map[hex.x][hex.y] <= -0.5 or map[hex.x][hex.y] >= 0.5 then

                else
                    map[hex.x][hex.y] = 2
                    win.scene"world":append(am.circle(hex_to_pixel(hex), get_default_hex_size(), COLORS.BLACK, 6))
                end
            end
            win.scene"coords".text = string.format("%2d,%2d", off.x, -off.y)
            win.scene"hex_cursor".center = hex_to_pixel(hex) + vec2(-278, -318)
        end
    else -- mouse is over background bar, (or outside window!)
        if win:key_pressed"escape" then
            init()
        end
    end
end

function update_score()
    win.scene"score".text = string.format("SCORE: %.2f", am.current_time())
end

function main_action(main_scene)
    update_score()
    poll_mouse()
end

function game_init()
    local score = am.translate(-264, win.top - 50) ^ am.text("", "left"):tag"score"
    local coords = am.translate(440, win.top - 50) ^ am.text(""):tag"coords"
    local hex_cursor = am.circle(vec2(win.left, win.top), get_default_hex_size(), vec4(0.4), 6):tag"hex_cursor"
    local curtain = am.rect(win.left, win.top, win.right, win.bottom, COLORS.BLUE_STONE):tag"curtain"

    local main_scene = am.group{
        random_map(),
        score,
        coords,
        curtain,
        hex_cursor
    }

    main_scene:action(am.series
    {
        am.tween(curtain, 0.8, { x2 = win.left }, am.ease.bounce),
        main_action
    })

    win.scene = main_scene
end

function draw_menu()
    local map = hexagonal_map(15, 9)
    local backdrop = am.group()

    for i,_ in pairs(map) do
        for j,e in pairs(map[i]) do
            backdrop:append(am.circle(hex_to_pixel(vec2(i, j)), 11, color_at(e), 6))
        end
    end

    local title_text = am.group
    {
        am.translate(0, 200) ^ am.scale(5) ^ am.text("hexyz", COLORS.WHITE, "right"),
        am.translate(0, 130) ^ am.scale(4) ^ am.text("a tower defense", COLORS.WHITE, 1),
        am.circle(vec2(0), 100, vec4(0.6), 6):tag"button", am.scale(4) ^ am.text("START", COLORS.BLACK)
    }

    win.scene = am.group
    {
        backdrop,
        title_text
    }
    :action(function(self)
        local mouse = win:mouse_position()
        if math.length(mouse) < 100 then
            self"button":action(am.series
            {
                am.tween(0.1, { color = COLORS.WHITE }),
                am.tween(0.1, { color = vec4(0.6) })
            })

            if win:mouse_pressed"left" then
                game_init()
            end
        end
    end)
end

function init()
    draw_menu()
end

init()
noglobals()

