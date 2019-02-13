----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] -------
--[[                                                    author@churchianity.ca

  ]]

require "hex"

----- [[ DUMMY FUNCTIONS ]] ----------------------------------------------------

function show_hex_coords()
    grid:action(function()
        grid:remove("text")
        
        mouse_position = vec2(win:mouse_position().x, win:mouse_position().y)

        if mouse_position.x < 268 then
            hex = map.retrieve(mouse_position)
            grid:append(am.translate(win.left + 30, win.top - 10) 
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

SPRITES = {"BoulderHills1.png", "BoulderHills2.png", "BoulderHills2.png",
           "Brambles1.png", "Brambles2.png", "Brambles3.png", "Brambles4.png",
           "BrownHills1.png", "BrownHills2.png", "BrownHills3.png", 
           "Grass1.png", "Grass2.png", "Grass3.png", "Grass4.png", "Grass5.png",           "Hills1.png", "Hills2.png", "Hills3.png", "Hills4.png", "Hills5.png",
           "HillsGreen1.png", "HillsGreen2.png", "HillsGreen3.png", 
           "LightGrass1.png", "LightGrass2.png", "LightGrass3.png",
           "LowHills1.png", "LowHills2.png", "LowHills3.png", "LowHills4.png",
           "Mountains1.png", "Mountains2.png", "Mountains3.png", 
           "Mud1.png", "Mud2.png", "Mud3.png", "Mud4.png", "Mud5.png",
           "Orchards1.png", "Orchards2.png", "Orchards3.png", "Orchards4.png",
           "PineForest1.png", "PineForest2.png", "PineForest3.png", 
           "Woods1.png", "Woods2.png", "Woods3.png", "Woods4.png"}

function rsprite()
    return string.format("res/%s", SPRITES[math.random(#SPRITES)])
end

----- [[ BLAH BLAH LBAH ]] -----------------------------------------------

win = am.window {
        title = "Warzone 2: Electric Boogaloo",
    
        -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10 Aspect Ratio
        width = 1280 * 3 / 4, -- 960
        height = 800 * 3 / 4} -- 600

----- [[ MAP RENDERING ]] ------------------------------------------------

function grid_init()
    grid = am.group()
    
    map = rectmap_init(layout_init(vec2(win.left, win.bottom)), 45, 31)
    
    grid:action(function() 
        for hex,pix in pairs(map) do
            grid:append(am.circle(pix, map.layout.size.x, rcolor(), 6))
        end
        return true
    end)    

    grid:append(am.translate(350, 200) 
             ^ am.scale(2) 
             ^ am.sprite("2.png"))

    show_hex_coords()

    return grid
end

function toolbar_init()
    local toolbar = am.group() 
    local toolbar_bg = vec4(0.4, 0.6, 0.8, 1)

    toolbar:append(am.rect(268, win.top, win.right, win.bottom, toolbar_bg))
    
    toolbar:append(am.particles2d({source_pos=vec2(win.width/2-268, win.top),
                                   source_pos_var=vec2(0, 600),
                                   angle=math.pi/4,
                                   start_color=vec4(0.9),
                                   gravity=vec2(100),
                                   start_color_var=rcolor(),
                                   start_size=3}))
    return toolbar 
end

function game_init()
    return am.group{grid_init(), toolbar_init()}
end

----- [[ MAIN ]] -----------------------------------------------------------

local map = {}

win.scene = game_init()

show_hex_coords()

