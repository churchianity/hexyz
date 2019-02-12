----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] -------
--[[                                                    author@churchianity.ca

  ]]

require "hex"

----- [[ DUMMY FUNCTIONS ]] ----------------------------------------------------

function show_hex_coords(map)
    test_scene:action(function()
        mouse_position = vec2(win:mouse_position().x, win:mouse_position().y)
        hex = map.retrieve(mouse_position)
        test_scene:remove("text")
        test_scene:append(am.translate(win.right - 30, win.top - 10) 
                        ^ am.text(string.format("%d,%d", hex.s, hex.t)))
    end)
end

function rcolor()
    return vec4(math.random(20, 80) / 100)
end

----- [[ BLAH BLAH LBAH ]] -----------------------------------------------

win = am.window {
        title = "Warzone 2: Electric Boogaloo",
    
        -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10 Aspect Ratio
        width = 1280 * 3 / 4, -- 960
        height = 800 * 3 / 4} -- 600

----- [[ MAP RENDERING ]] ------------------------------------------------

function game_scene(layout)
    map = map_rectangular_init(layout, 45, 31) 
    hexagons = am.group()

    for _,hex in pairs(map) do
        hexagons:append(
            am.circle(hex, layout.size.x, rcolor(), 6):tag(tostring(hex)))
    end
    return hexagons
end

----- [[ MAIN ]] -----------------------------------------------------------

map = {}
game_scene = game_scene(layout_init(vec2(win.left, win.bottom)))

test_scene = am.group()

win.scene = am.group{test_scene, game_scene}

show_hex_coords(map)

