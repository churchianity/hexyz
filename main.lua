----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] --------
--[[                                                    author@churchianity.ca

  ]]

require "hex"
require "util"

local world 


local guibgcolor = vec4(0.5, 0.5, 0.2, 0)

local win = am.window{
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px
   
    title = "Warzone 2: Electric Boogaloo"}

function show_axes()
    xaxis = am.line(vec2(win.left, 0), vec2(win.right, 0))
    yaxis = am.line(vec2(0, win.top), vec2(0, win.bottom)) 
    world:append(am.group{xaxis, yaxis}:tag("axes"))
end

function world_init()
    world = am.group()
    local layout = layout_init(vec2(-402, win.bottom))
    local map = rectmap_init(45, 31)
    local lgui = am.group(
                 am.rect(win.left, win.top, -402, win.bottom, guibgcolor))
    local rgui = am.group(
                 am.rect(win.right, win.top, 402, win.bottom, guibgcolor))

    world:append(lgui)
    world:append(rgui)

    world:action(coroutine.create(function()
        for hex,_ in pairs(map) do
            world:append(am.circle(hex_to_pixel(hex, layout), 11, rrgb(1), 6))
            am.wait(am.delay(0.01))
        end
    end))

end

function init()
    world_init()
    show_axes()
    win.scene = world
end

----- [[ MAIN ]] ---------------------------------------------------------------

init()

