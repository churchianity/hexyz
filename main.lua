----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] -------
--[[                                                    author@churchianity.ca

  ]]

require "hex"

----- [[ DUMMY FUNCTIONS ]] ----------------------------------------------------

function show_hex_coords()
    gui_scene:action(function()
        gui_scene:remove("text")
        
        mouse_position = vec2(win:mouse_position().x, win:mouse_position().y)

        if mouse_position.x < 268 then
            hex = map.retrieve(mouse_position)
            gui_scene:append(am.translate(win.left + 30, win.top - 10) 
                            ^ am.text(string.format("%d,%d", hex.s, hex.t)))
        end
    end)
end

function rcolor()
    return vec4(math.random(20, 80) / 100,
                math.random(20, 80) / 100,
                math.random(20, 80) / 100,
                1)
end

----- [[ BLAH BLAH LBAH ]] -----------------------------------------------

win = am.window {
        title = "Warzone 2: Electric Boogaloo",
    
        -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10 Aspect Ratio
        width = 1280 * 3 / 4, -- 960
        height = 800 * 3 / 4} -- 600

----- [[ MAP RENDERING ]] ------------------------------------------------

function map_init(layout)
    map = rectmap_init(layout, 45, 31) 

    map_scene:action(function() 
        for _,hex in pairs(map) do
            if hex_equals(_, vec2(23, 16)) then
                print("yay")
            else
                map_scene:append(am.circle(hex, layout.size.x, rcolor(), 6))
            end
        end
        
        map_scene:append(am.rect(268, win.top, win.right, win.bottom, vec4(0.4, 0.6, 0.8, 1)))
        
        local coalburner = [[
        .........
        ..kkkkk..
        .k.....k.
        k..wo...k
        k..ooo..k
        k...o...k
        .k.....k.
        ..kkkkk..
        .........
        ]]
        
        map_scene:append(am.translate(350, 200) ^ am.scale(10) ^ am.sprite(coalburner))
        
        map_scene:append(am.particles2d({source_pos=vec2(400, win.top),
                                         source_pos_var=vec2(0, 600),
                                         angle=math.pi/4,
                                         start_color=vec4(0.9),
                                         gravity=vec2(100),
                                         start_color_var=rcolor(),
                                         start_size=5}))
        --print(win.right - 268)

        return true
    end)
end

----- [[ MAIN ]] -----------------------------------------------------------

map = {}

gui_scene = am.group()
map_scene = am.group(); map_init(layout_init(vec2(win.left, win.bottom)))

win.scene = am.group{map_scene, gui_scene}

show_hex_coords(map)

