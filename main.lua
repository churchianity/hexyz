----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] --------
--[[                                                    author@churchianity.ca
  ]]

require "hex"
require "util"

------ [[ GLOBALS ]] -----------------------------------------------------------

local win = am.window{
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px
    title = "Warzone 2: Electric Boogaloo",
    clear_color = vec4(22/255, 22/255, 29/255, 1)
    }

local title
local world
local layout = hex_layout()
local map = hex_hexagonal_map(24)

----- [[ SPRITES ]] ------------------------------------------------------------
local titlebutton = [[
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
KwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KwbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbK
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
    ]]

function world_init()
    world = am.group{}
    world:action(coroutine.create(function()
        for hex,_ in pairs(map) do
            world:append(am.circle(hex_to_pixel(hex, layout), 12, rrgb(1), 6))
            am.wait(am.delay(0.01))
        end
    end))
    win.scene = world
end

function init()

    local titlemenu = am.group{
        am.translate(0, 150)
        ^ {am.scale(6.5)
        ^ am.text("WARZONE 2", vec4(0, 0, 0, 1)),
        am.scale(6.3, 6.7)
        ^ am.text("WARZONE 2")},

        am.translate(0, 80)
        ^ am.text("a tower defense game"),

        am.translate(0, 0)
        ^ {am.scale(3)
        ^ am.sprite(titlebutton),
        am.text("NEW GAME")},

        am.translate(0, -40)
        ^ {am.scale(3)
        ^ am.sprite(titlebutton),
        am.text("LOAD GAME")},

        am.translate(0, -80)
        ^ {am.scale(3)
        ^ am.sprite(titlebutton),
        am.text("SETTINGS")},

        am.translate(0, -120)
        ^ {am.scale(3)
        ^ am.sprite(titlebutton),
        am.text("QUIT")},

        am.translate(0, -250)
        ^ am.text("by nick hayashi")
        }

    local backdrop = am.group()

    for hex,_ in pairs(map) do
        local center = hex_to_pixel(hex, layout)
        backdrop:append(am.circle(center, 12, rhue(1), 6))
    end

    title = am.group{
        am.translate(win.right, win.bottom)
        ^ am.scale(3.5, 1.5)
        ^ am.rotate(0)
        ^ backdrop,

        titlemenu
        }:action(function()
            title"rotate".angle = am.frame_time / 36
        end)

    win.scene = title
end

----- [[ MAIN ]] ---------------------------------------------------------------

init()

