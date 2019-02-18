----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] --------
--[[                                                    author@churchianity.ca
  ]]

require"hex"
require"util"

------ [[ GLOBALS ]] -----------------------------------------------------------

local win = am.window{
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px
    title = "Warzone 2: Electric Boogaloo",
    resizable = false
    }

local layout    = layout(vec2(-268, win.bottom))
local map       = rectangular_map(45, 31)
local world     = am.group{}:tag"world"

----- [[ SPRITES ]] ------------------------------------------------------------

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
----- [[ FUNCTIONS ]] ----------------------------------------------------------

function show_axes()
    local xaxis = am.line(vec2(win.left, 0), vec2(win.right, 0))
    local yaxis = am.line(vec2(0, win.top), vec2(0, win.bottom))
    win.scene:append(am.translate(0, 0) ^ am.group{xaxis, yaxis}:tag"axes")
end

function show_hex_coords()
    win.scene:action(function()
        win.scene:remove("coords")
        
        local mouse = axial_to_doubled(pixel_to_hex(win:mouse_position(), layout))
        
        if mouse.x > 0 and mouse.x < 45 and mouse.y < 0 and mouse.y > -63 then
            local coords = am.group{
                am.translate(win.left + 30, win.top - 10)
                ^ am.text(string.format("%d,%d", mouse.x, mouse.y)):tag"coords"}
                win.scene:append(coords)
        end 
    end)
end

function init()
    for hex,_ in pairs(map) do
        local pix = hex_to_pixel(hex, layout)
        world:append(am.circle(pix, 11, rhue(1), 6)) 
    end
    
    win.scene = world
end

----- [[ MAIN ]] ---------------------------------------------------------------

init()
show_hex_coords()
