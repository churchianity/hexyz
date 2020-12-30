
local hot
local active

function button(x, y)
   local color = (x + y) % 2 == 0 and vec4(0.4, 0.4, 0.5, 1) or vec4(0.5, 0.4, 0.4, 1)
   return am.translate(x * 80, y * 80) ^ am.rect(-40, 40, 40, -40, color)
end

