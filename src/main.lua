
require"hex"

--[[============================================================================
    ----- COLOR CONSTANTS -----
============================================================================]]--
local EIGENGRAU = vec4(0.08, 0.08, 0.11, 1)

-- Ethan Schoonover Solarized Colorscheme
local BASE03  = vec4(0   , 0.16, 0.21, 1)
local BASE02  = vec4(0.02, 0.21, 0.25, 1)
local BASE01  = vec4(0.34, 0.43, 0.45, 1)
local BASE00  = vec4(0.39, 0.48, 0.51, 1)
local BASE0   = vec4(0.51, 0.58, 0.58, 1)
local BASE1   = vec4(0.57, 0.63, 0.63, 1)
local BASE2   = vec4(0.93, 0.90, 0.83, 1)
local BASE3   = vec4(0.99, 0.96, 0.89, 1)
local YELLOW  = vec4(0.70, 0.53, 0   , 1)
local ORANGE  = vec4(0.79, 0.29, 0.08, 1)
local RED     = vec4(0.86, 0.19, 0.18, 1)
local MAGENTA = vec4(0.82, 0.21, 0.50, 1)
local VIOLET  = vec4(0.42, 0.44, 0.76, 1)
local BLUE    = vec4(0.14, 0.54, 0.82, 1)
local CYAN    = vec4(0.16, 0.63, 0.59, 1)
local GREEN   = vec4(0.52, 0.60, 0   , 1)

am.ascii_color_map =
{
    E = EIGENGRAU,
    K = BASE03,
    k = BASE02,
    L = BASE01,
    l = BASE00,
    s = BASE0,
    S = BASE1,
    w = BASE2,
    W = BASE3,
    y = YELLOW,
    o = ORANGE,
    r = RED,
    m = MAGENTA,
    v = VIOLET,
    b = BLUE,
    c = CYAN,
    g = GREEN
}

--[[============================================================================
    ----- SETUP -----
============================================================================]]--
local win = am.window
{
    -- base resolution = 3/4 * WXGA standard 16:10
    width = 1280 * 3/4,                     -- 960px
    height = 800 * 3/4,                     -- 600px

    clear_color = BASE03
}

local map       = rectangular_map(45, 31, {2, 4, 8})
local layout    = layout(vec2(-268, win.bottom))
local home      = hex_to_pixel(vec2(23, 4), layout)

--[[============================================================================
    ----- SCENE GRAPH / NODES -----
============================================================================]]--
local panel; local world; local game                                        --[[

  panel
    |
    +------> game ------> win.scene
    |
  world

                                                                            ]]--
local backdrop; local menu; local title                                     --[[

 backdrop
    |
    +------> title ------> win.scene
    |
   menu

--[[============================================================================
    ----- FUNCTIONS -----
============================================================================]]--

--
function keep_time()
    local offset = am.current_time()

    game:action(function()
        game:remove("time")

        local time_str = string.format("%.2f", am.current_time() - offset)

        game:append(
            am.translate(-374, win.top - 10)
            ^ am.text(time_str):tag"time")
    end)
end

-- TODO refactor to something like - poll-mouse or mouse-hover event
function show_coords()
    game:action(function()
        game:remove("coords")
        game:remove("selected")

        local hex = pixel_to_hex(win:mouse_position(), layout)
        local mouse = hex_to_offset(hex)

        -- check mouse is within bounds of game map
        if mouse.x > 0 and mouse.x < map.width and
           -mouse.y > 0 and -mouse.y < map.height then -- north is positive

            local text = am.text(string.format("%d,%d", mouse.x, mouse.y))
            local coords = am.group{
                am.translate(win.right - 25, win.top - 10)
                ^ am.text(string.format("%d,%d", mouse.x,-mouse.y)):tag"coords"}

            world:append(coords)

            local color = vec4(0, 0, 0, 0.2)
            local pix = hex_to_pixel(hex, layout)
            world:append(am.circle(pix, layout.size.x, color, 6):tag"selected")
        end
    end)
end

--
function title_init()
    backdrop = am.group{}:tag"backdrop"
    menu = am.group{}:tag"menu"
    title = am.group{menu, backdrop}:tag"title"
end

--
function game_init()
    -- setup nodes
    world = am.group{}:tag"world"
    panel = am.group{}:tag"panel"
    game = am.group{world, panel}:tag"game"

    -- render world
    world:action(coroutine.create(function()

        -- background panel for gui elements
        panel:append(am.rect(win.left, win.top, -268, win.bottom):tag"bg")

        -- begin map generation
        for hex,noise in pairs(map) do

            -- determine cell color based on noise
            local color

            -- impassable
            if noise < -0.5 then
                color = vec4(0.10, 0.30, 0.20, (noise + 1) / 2)

            -- passable
            elseif noise < 0 then
                color = vec4(0.10, 0.25, 0.05, (noise + 1.9) / 2)

            -- passable
            elseif noise < 0.5 then
                color = vec4(0.25, 0.20, 0.10, (noise + 1.9) / 2)

            -- impassable
            else
                color = vec4(0.10, 0.30, 0.20, (noise + 1) / 2)
            end

            -- determine cell shading mask based on map position
            local off = hex_to_offset(hex)
            local mask = vec4(0, 0, 0, math.max(((off.x-23)/45)^2,
                                               ((-off.y-16)/31)^2))
            color = color - mask

            -- determine hexagon center for drawing
            local center = hex_to_pixel(hex, layout)

            -- prepend hexagon to screen
            world:prepend(am.circle(center, 11, color, 6):tag(tostring(hex)))

            -- fade in bg panel
            panel"bg".color = BASE03

            -- sleep
            --am.wait(am.delay(0.01))
        end
        -- home base
        world:append(am.translate(home)
                     ^ am.rotate(0):tag"homer"
                     ^ am.circle(vec2(0), 22, ORANGE, 3)):tag"home"

        world:append(am.translate(home)
                     ^ am.rotate(60):tag"homer2"
                     ^ am.circle(vec2(0), 22, YELLOW, 3)):tag"home"

        world:action(function()
            world"homer".angle = am.frame_time / 6
            world"homer2".angle = am.frame_time / 3
        end)

        show_coords()   -- mouse-hover events
        keep_time()     -- scoring
    end))
    win.scene = game -- make it so
end

--[[============================================================================
    ----- MAIN -----
============================================================================]]--

game_init()

