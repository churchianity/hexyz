--[[ WARZONE 2 - HEXAGONAL GRID RESOURCE BASED TOWER DEFENSE GAME]]
--[[

  ]]

require "hex"

-- ENTRY POINT -----------------------------------------------------------------
win = am.window {
    title = "Warzone 2: Electric Boogaloo",

    -- BASE RESOLUTION = 3/4 * WXGA Standard 16:10 Aspect Ratio
    width = 1280 * 3 / 4,
    height = 800 * 3 / 4,

    clear_color = vec4(0, 0, 0, 0)
}

-- GROUPS
local grid = am.group()

--[[
xaxis = am.line(vec2(-win.width / 2, 0) , vec2(win.width / 2, 0))
yaxis = am.line(vec2(0, -win.height / 2), vec2(0, win.height / 2))

grid:append(xaxis)
grid:append(yaxis)
--]]

win.scene = grid


