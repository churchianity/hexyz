
require"hex"
require"util"

--[[============================================================================
                            ----- GLOBALS -----
==============================================================================]]

local win = am.window{
    -- base resolution = 3/4 * WXGA standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px
    
    clear_color = vec4(0.01, 34/255, 45/255, 0),
    title = "Warzone 2: Electric Boogaloo",
    resizable = false,
    }

local layout    = layout(vec2(-268, win.top - 10))
local map       
local world     = am.group{}:tag"world"

--[[============================================================================
                            ----- FUNCTIONS -----
==============================================================================]]

function show_hex_coords()
    world:action(function()
        world:remove("coords")
        world:remove("select")
        
        local hex = pixel_to_cube(win:mouse_position(), layout)
        local mouse = cube_to_offset(hex)
        
        if mouse.x > 0 and mouse.x < map.width and 
           mouse.y > 0 and mouse.y < map.height then
            local coords = am.group{
                am.translate(win.right - 25, win.top - 10)
                ^ am.text(string.format("%d,%d", mouse.x, mouse.y)):tag"coords"}
                world:append(coords)
            
            local mask = vec4(1, 1, 1, 0.2)
            local pix = cube_to_pixel(hex, layout)
            world:append(am.circle(pix, layout.size.x, mask, 6):tag"select") 
        end 
    end)
end

function world_init()
    world:action(coroutine.create(function()
        -- init guiblock 
        local bg = am.rect(win.left, win.top, -268, win.bottom):tag"bg"
        world:append(bg)
        
        -- init map
        map = rectangular_map(45, 31)
        for hex,elevation in pairs(map) do
            local pix = cube_to_pixel(hex, layout)
            local off = cube_to_offset(hex)
            local tag = tostring(hex)
            local color
            local mask 

            -- testing noise with color
            color = vec4(1, 1, 1, (elevation + 1) / 2)

            -- determine cell shading mask based on map position
            --mask = vec4(0, 0, 0, math.max(((off.x-23)/30)^2, ((off.y-16)/20)^2))
            --color = color - mask

            world"bg".color = vec4(0, 43/255, 54/255, am.frame_time)
            world:prepend(am.circle(pix, layout.size.x, color, 6):tag(tag))
            am.wait(am.delay(0.01))
        end
        show_hex_coords()
    end))
    win.scene = world
end

--[[============================================================================
                            ----- MAIN -----
==============================================================================]]

world_init()


