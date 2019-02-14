----- [[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]] --------
--[[                                                    author@churchianity.ca
  ]]

require "hex"
require "util"

local win = am.window{
    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10
    width = 1280 * 3 / 4, -- 960px
    height = 800 * 3 / 4, -- 600px

    title = "Warzone 2: Electric Boogaloo"}

local title = am.group()
local world = am.group()
local layout = hex_layout(vec2(-368, win.bottom))
local map = hex_rectangular_map(45, 31)
local titlemap = hex_spiral_map(vec2(0), 10)
local titlelayout = hex_layout(vec2(win.right, win.bottom))

function show_axes()
    xaxis = am.line(vec2(win.left, 0), vec2(win.right, 0))
    yaxis = am.line(vec2(0, win.top), vec2(0, win.bottom)) 
    world:append(am.group{xaxis, yaxis}:tag("axes"))
end

function world_init()
    world:action(coroutine.create(function()
        for hex,_ in pairs(map) do
            world:append(am.circle(hex_to_pixel(hex, layout), 11, rrgb(1), 6))
            am.wait(am.delay(0.01))
        end
    end))

end

function init()
    local rotatable = am.group(am.rotate(45):tag"rotatable")
    local backdrop = am.group{rotatable}

    for _,hex in pairs(titlemap) do
        local center = hex_to_pixel(hex, titlelayout)
        rotatable:append(am.circle(center, 11, rrgb(1), 6))
    end

    local line1 = am.text("WARZONE 2")
    local line2 = am.text("Electric Boogaloo")
    local line3 = am.text("by Nick Hayashi")
    local title = am.group{backdrop,
        am.translate(0, 150) ^ am.scale(4) ^ line1,
        am.translate(0, 100) ^ am.scale(3) ^ line2,
        am.translate(0, 60)  ^ am.scale(1) ^ line3
    }:action(function()
        rotatable"rotatable".angle = (am.frame_time / 5)
   end)
   win.scene = title
end

----- [[ MAIN ]] ---------------------------------------------------------------

init()

