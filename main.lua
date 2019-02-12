----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] -------
--[[                                                    author@churchianity.ca

  ]]

require "hex"

----- [[ DUMMY FUNCTIONS ]] ------------------------------------------------------

function draw_axes()
    xaxis = am.line(vec2(-win.width / 2, 0) , vec2(win.width / 2, 0))
    yaxis = am.line(vec2(0, -win.height / 2), vec2(0, win.height / 2))

    title_scene:append(xaxis)
    title_scene:append(yaxis)
end

function rcolor()
    return vec4(math.random(20, 80) / 100)
end

----- [[ BLAH BLAH LBAH ]] -----------------------------------------------

local win = am.window {
    title = "Warzone 2: Electric Boogaloo",
    
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10 Aspect Ratio
    width = 1280 * 3 / 4, -- 960
    height = 800 * 3 / 4} -- 600

local layout = layout_init({win.left, win.bottom}) 

----- [[ MAP RENDERING ]] ------------------------------------------------

function render_map(layout)
    map = map_rectangular_init(layout, 45, 31) 
    hexagons = am.group()

    for _,v in pairs(map) do
        hexagons:append(am.circle(vec2(unpack(v)), layout.size[1], rcolor(), 6))
    end
    return hexagons
end

----- [[ MAIN ]] -----------------------------------------------------------

local game_scene = render_map(layout)
local test_scene = am.group()

win.scene = am.group{test_scene, game_scene}

test_scene:action(function() 
    x, y = unpack(pixel_to_hex(win:mouse_position().x, win:mouse_position().y, layout))
    test_scene:remove_all("text")
    test_scene:append(am.translate(vec2(unpack(hex_to_pixel(x, y, layout)))) ^ am.text(string.format("%d, %d", x, y)))
end)
