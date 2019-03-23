
require"hexyz"

math.randomseed(os.time())

--[[============================================================================
    ----- GLOBALS -----
============================================================================]]--

-- Ethan Schoonover Solarized Colorscheme w/ Eigengrau
local EIGENGRAU = vec4(0.08, 0.08, 0.11, 1)
local BASE03  = vec4(0   , 0.16, 0.21, 1)
local BASE02  = vec4(0.02, 0.21, 0.25, 1)
local BASE01  = vec4(0.34, 0.43, 0.45, 1)
local BASE00  = vec4(0.39, 0.48, 0.51, 1)
local BASE0   = vec4(0.51, 0.58, 0.58, 1)
local BASE1   = vec4(0.57, 0.63, 0.63, 1)
local BASE2   = vec4(0.93, 0.90, 0.83, 1)
local BASE3   = vec4(0.99, 0.96, 0.89, 1)
local YELLOW  = vec4(0.70, 0.53, 0,    1)
local ORANGE  = vec4(0.79, 0.29, 0.08, 1)
local RED     = vec4(0.86, 0.19, 0.18, 1)
local MAGENTA = vec4(0.82, 0.21, 0.50, 1)
local VIOLET  = vec4(0.42, 0.44, 0.76, 1)
local BLUE    = vec4(0.14, 0.54, 0.82, 1)
local CYAN    = vec4(0.16, 0.63, 0.59, 1)
local GREEN   = vec4(0.52, 0.60, 0   , 1)

local win = am.window
{
    -- Base Resolution = 3/4 * WXGA standard 16:10
    width = 1280 * 3/4, -- 960px
    height = 800 * 3/4, -- 600px

    clear_color = EIGENGRAU
}

local curtain = am.rect(win.left, win.top, win.right, win.bottom
                      , vec4(0, 0, 0, 0.7)) -- Color

--local log = io.open(os.date("log %c.txt"), "w")

--[[============================================================================
    ----- ROUTINES -----
============================================================================]]--

-- Template for Buttons
function rect_button(text)
    return am.group
    {
        am.rect(-150, -20, 150, 20, vec4(0)):action(am.tween(1, {color=BASE2{a=0.4}})),
        am.text(text, vec4(0)):action(am.tween(1, {color=BASE02}))
    }
end


--
function text_field(tag)
    local field = am.text(""):action(function()

        -- Special Cases
        if win:key_pressed("backspace") then
            field.text = field.text:sub(1, -2)

        elseif win:key_pressed("enter") then
            field.text = ""

        -- I Only Use This To Get Seeds At The Moment
        elseif win:key_pressed("0") then field.text = field.text .. 0
        elseif win:key_pressed("1") then field.text = field.text .. 1
        elseif win:key_pressed("2") then field.text = field.text .. 2
        elseif win:key_pressed("3") then field.text = field.text .. 3
        elseif win:key_pressed("4") then field.text = field.text .. 4
        elseif win:key_pressed("5") then field.text = field.text .. 5
        elseif win:key_pressed("6") then field.text = field.text .. 6
        elseif win:key_pressed("7") then field.text = field.text .. 7
        elseif win:key_pressed("8") then field.text = field.text .. 8
        elseif win:key_pressed("9") then field.text = field.text .. 9
        end
    end)
    return field:tag(tag)
end


-- Tween Multiple Nodes of the Same Type
function multitween(nodes, time, values)
    for _,node in pairs(nodes) do
        node:action(am.tween(time, values))
    end
end


-- Returns Appropriate Tile Color for Specified Elevation
function color_at(elevation)
    if elevation < -0.5 then -- Lowest Elevation : Impassable
        return vec4(0.10, 0.30, 0.40, (elevation + 1.2) / 2)

    elseif elevation < 0 then -- Med-Low Elevation : Passable
        return vec4(0.10, 0.25, 0.10, (elevation + 1.8) / 2)

    elseif elevation < 0.5 then -- Med-High Elevation : Passable
        return vec4(0.25, 0.20, 0.10, (elevation + 1.6) / 2)

    else                        -- Highest Elevation : Impassable
        return vec4(0.15, 0.30, 0.20, (elevation + 1.0) / 2)
    end
end


-- Handler for Scoring
function keep_score()
    local offset = am.current_time()

    win.scene:action(function()
        win.scene:remove("time")

        local time_str = string.format("%.2f", am.current_time() - offset)

        win.scene:append(am.translate(-374, win.top - 10)
                         ^ am.text(time_str):tag"time")
    end)
end


-- In-Game Pause Menu
function pause()
    win.scene:append(curtain:tag"curtain")
    win.scene:append(am.group
    {
        am.rect(-200, 150, 200, -150, BASE03{a=0.9})
    }:tag"menu")

    -- Event Handler
    win.scene:action(function()

        -- Back to Main Game
        if win:key_pressed("escape") then
            win.scene:remove("curtain"); win.scene:remove("menu")
            game_action(); return true
        end
    end)
end





-- Returns Node
function draw_(map)
    local world = am.group():tag"world"

    for hex,elevation in pairs(map) do

        local off = hex_to_offset(hex)
        local mask = vec4(0, 0, 0, math.max(((off.x - 23) / 45) ^ 2,
                                           ((-off.y - 16) / 31) ^ 2))

        local color = color_at(elevation) - mask
        local node = am.circle(hex_to_pixel(hex, vec2(11)), 11, vec4(0), 6)
        node:action(am.tween(0.3, {color = color})) -- fade in

        world:append(node:tag(tostring(hex))) -- unique identifier
    end
    return world
end


--
function ghandler(game)
    win.scene:remove("coords"); win.scene:remove("selected")

    -- Pause Game
    if win:key_pressed("escape") then
        pause(); return true
    end

    local hex = pixel_to_hex(win:mouse_position(), vec2(11)) - vec2(10, 10)
    local mouse = hex_to_offset(hex)

    -- Check if Mouse is Within Bounds of Game Map
    if mouse.x > 0 and mouse.x < map.width and
        -mouse.y > 0 and -mouse.y < map.height then -- North is Positive

        local text = am.text(string.format("%d,%d", mouse.x, mouse.y))
        game:append(am.translate(450, 290) ^ text:tag"coords")

        local color = vec4(0, 0, 0, 0.4)
        local pix = hex_to_pixel(hex, vec2(11))
        game:append(am.circle(pix, 11, color, 6):tag"selected")
    end
end


-- Begin Game - From Seed or Random Seed (if ommitted)
function game_init(seed)
    local game = am.group()

    game:append(am.rect(win.left, win.top, -268, win.bottom, BASE03))



    map = rectangular_map(45, 31, seed)
    game:action(ghandler)
    win.scene = am.group(am.translate(-268, -300) ^ draw_(map), game)
end


-- Title Action
function thandler(title)
    local mouse = win:mouse_position()

    if mouse.x > -150 and mouse.x < 150 then

        -- Button 1
        if mouse.y > -70 and mouse.y < -30 then

            title"button1""rect":action(am.tween(0.5, {color = BASE2{a=1}}))

            if win:mouse_pressed("left") then
                win.scene:action(am.play(am.sfxr_synth(57784609)))
                game_init(map.seed)
                return true
            end

        -- Button 2
        elseif mouse.y > -120 and mouse.y < -80 then

            title"button2""rect":action(am.tween(0.5, {color = BASE2{a=1}}))

            if win:mouse_pressed("left") then
                win.scene:action(am.play(am.sfxr_synth(91266909)))
            end

        -- Button 3
        elseif mouse.y > -170 and mouse.y < -130 then

            title"button3""rect":action(am.tween(0.5, {color = BASE2{a=1}}))

            if win:mouse_pressed("left") then
                local synth_seed = math.random(100000000)
                win.scene:action(am.play(am.sfxr_synth(synth_seed)))
                print(synth_seed)
            end

        -- Button 4
        elseif mouse.y > -220 and mouse.y < -180 then

            title"button4""rect":action(am.tween(0.5, {color = BASE2{a=1}}))

            if win:mouse_pressed("left") then
                win.scene:action(am.play(am.sfxr_synth(36002209)))
            end
        else
            multitween({title"button1""rect", title"button2""rect",
                        title"button3""rect", title"button4""rect"},
                        0.5, {color = BASE2{a=0.4}})
        end
    else
        multitween({title"button1""rect", title"button2""rect",
                    title"button3""rect", title"button4""rect"},
                    0.5, {color = BASE2{a=0.4}})
    end
end


-- Setup and Display Title Screen
function title_init()
    local title = am.group()

    title:append(am.translate(0, -50) ^ rect_button("NEW SCENARIO"):tag"button1")
    title:append(am.translate(0, -100) ^ rect_button("LOREMIPSUM"):tag"button2")
    title:append(am.translate(0, -150) ^ rect_button("FUN BUTTON"):tag"button3")
    title:append(am.translate(0, -200) ^ rect_button("SETTINGS"):tag"button4")

    map = hexagonal_map(45)
    backdrop = am.scale(1.3) ^ am.rotate(0) ^ draw_(map)

    backdrop:action(function()
        backdrop"rotate".angle = am.frame_time / 40 + 45
    end)

    -- Event Handler
    title:action(thandler)

    win.scene = am.group(backdrop, title)
end


-- Alias
function init()
    title_init()
end

--=============================================================================
    ----- Main -----


init()

