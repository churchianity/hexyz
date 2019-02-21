----- WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME -------------
--                                                        author@churchianity.ca
  

require"hex"
require"util"

------ GLOBALS -----------------------------------------------------------------

local win = am.window{
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px
    title = "Warzone 2: Electric Boogaloo",
    resizable = false
    }

local layout    = layout(vec2(-268, win.top - 10))
local map       = rectangular_map(45, 31)
local world     = am.group{}:tag"world"

-- modified ethan shoonover solarized colortheme
am.ascii_color_map = {
    E = vec4( 22/255,  22/255,  29/255, 1), -- eigengrau

    K = vec4(  0,      43/255,  54/255, 1), -- dark navy
    k = vec4(  7/255,  54/255,  66/255, 1), -- navy
    L = vec4( 88/255, 110/255, 117/255, 1), -- gray1
    l = vec4(101/255, 123/255, 131/255, 1), -- gray2

    s = vec4(131/255, 148/255, 150/255, 1), -- gray3
    S = vec4(147/255, 161/255, 161/255, 1), -- gray4
    w = vec4(238/255, 232/255, 213/255, 1), -- bone
    W = vec4(253/255, 246/255, 227/255, 1), -- white

    y = vec4(181/255, 137/255,   0,     1), -- yellow
    o = vec4(203/255,  75/255,  22/255, 1), -- orange
    r = vec4(220/255,  50/255,  47/255, 1), -- red
    m = vec4(211/255,  54/255, 130/255, 1), -- magenta
    v = vec4(108/255, 113/255, 196/255, 1), -- violet
    b = vec4( 38/255, 139/255, 210/255, 1), -- blue
    c = vec4( 42/255, 161/255, 152/255, 1), -- cyan
    g = vec4(133/255, 153/255,   0,     1)  -- green
}
local titlebutton =
[[
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
KwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
]]
----- FUNCTIONS ----------------------------------------------------------

function show_axes()
    local xaxis = am.line(vec2(win.left, 0), vec2(win.right, 0))
    local yaxis = am.line(vec2(0, win.top), vec2(0, win.bottom))
    win.scene:append(am.translate(0, 0) ^ am.group{xaxis, yaxis}:tag"axes")
end

function show_hex_coords()
    win.scene:action(function()
        win.scene:remove("coords")
        win.scene:remove("select")
        
        local hex = pixel_to_cube(win:mouse_position(), layout)
        local mouse = cube_to_offset(hex)
        
        if mouse.x > 0 and mouse.x < map.width and 
           mouse.y > 0 and mouse.y < map.height then
            local coords = am.group{
                am.translate(win.right - 25, win.top - 10)
                ^ am.text(string.format("%d,%d", mouse.x, mouse.y)):tag"coords"}
                win.scene:append(coords)
            
            local mask = vec4(1, 1, 1, 0.2)
            local pix = cube_to_pixel(hex, layout)
            world:append(am.circle(pix, layout.size.x, mask, 6):tag"select") 
        end 
    end)
end

function init()
    world:action(coroutine.create(function()
        local gui = am.rect(win.left, win.top, -268, win.bottom):tag"gui"
        world:append(gui)
        
        for hex,_ in pairs(map) do
            local pix = cube_to_pixel(hex, layout)
            local off = cube_to_offset(hex)
            local tag = tostring(hex)
            local color 

            if off.x == 0 or off.x == map.width or
                off.y == 0 or off.y == map.height then
                color = rhue(0.3)
            else
                color = rhue(1 - math.max(((off.x-23)/30)^2, ((off.y-16)/20)^2))
            end

            world"gui".color = vec4(0, 43/255, 54/255, am.frame_time / 20)
            world:prepend(am.circle(pix, layout.size.x, color, 6):tag(tag))
            
            am.wait(am.delay(0.01))
        end
    end))
    win.scene = world
end

----- [[ MAIN ]] ---------------------------------------------------------------

init()
show_hex_coords()

