
require"hexyz"

math.randomseed(os.time()); math.random(); math.random(); math.random()

win = am.window
{
   -- Base Resolution = 3/4 * WXGA standard 16:10
   width = 1280 * 3/4, -- 960px
   height = 800 * 3/4, -- 600px
   resizable = false,
   clear_color = vec4(0.08, 0.08, 0.11, 1)
}

local bias = "right"

local map
local world
local home
local home_node


function keep_score()
   local offset = am.current_time()
   local score = am.text(string.format("%.2f", am.current_time()))

   win.scene:append(am.translate(-380, 290) ^ score)
   win.scene:action(function()
      score.text = string.format("%.2f", am.current_time())
   end)
end


function show_hex_coords()
   local hex = pixel_to_hex(win:mouse_position(), vec2(11))
   local off = hex_to_offset(hex)
   local coords = am.text(string.format("%d,%d", off.x, off.y))
   win.scene:append(am.translate(380, 280) ^ coords
   :action(function()
      local hex = pixel_to_hex(win:mouse_position(), vec2(11))
      local off = hex_to_offset(hex)
      coords.text = string.format("%d,%d", off.x, off.y)
   end))
end


function explosion(position, size, color, color_var, sound) end

-- ensure home-base is somewhat of an open area.
function find_home(preferred_radius)
   home = spiral_map(vec2(23, 4), preferred_radius or 2)
   home_node = am.group()

   repeat
      local happy = true

      for i,h in pairs(home) do
         local elevation = hash_retrieve(map, h)

         if not elevation then -- hex not in map
         elseif elevation > 0.5 or elevation < -0.5 then
            happy = false

         elseif not happy then
            home = spiral_map(vec2(23, 4), preferred_radius or 2)
            home_node = am.group()

         else
            local center = hex_to_pixel(h, vec2(11))
            local color = vec4(1, 0, 0.5, 1)
            local node = am.circle(center, 4, color, 4)
            home_node:append(node)
         end
      end
   until happy
   return home_node
end


-- map elevation to appropriate tile color.
function color_at(elevation)
   if elevation < -0.5 then -- Lowest Elevation : Impassable
      return vec4(0.10, 0.30, 0.40, (elevation + 1.4) / 2 + 0.2)

   elseif elevation < 0 then -- Med-Low Elevation : Passable
      return vec4(0.10, 0.25, 0.10, (elevation + 1.8) / 2 + 0.2)

   elseif elevation < 0.5 then -- Med-High Elevation : Passable
      return vec4(0.25, 0.20, 0.10, (elevation + 1.6) / 2 + 0.2)

   elseif elevation < 1 then     -- Highest Elevation : Impassable
      return vec4(0.15, 0.30, 0.20, (elevation + 1.0) / 2 + 0.2)
   else
      return vec4(0.5, 0.5, 0.5, 1)
   end
end


function cartograph()
   map = rectangular_map(46, 33); math.randomseed(map.seed)
   world = am.group()

   for hex,elevation in pairs(map) do
      -- subtle shading for map edges. unnecessary, really.
      local off = hex_to_offset(hex)
      local mask = vec4(0, 0, 0, math.max(((off.x - 23.5) / 46) ^ 2,
                                         ((-off.y - 16.5) / 32) ^ 2))
      local color = color_at(elevation) - mask

      local node = am.circle(hex_to_pixel(hex, vec2(11)), 11, vec4(0), 6)
      :action(am.tween(5, {color=color}, am.ease.out(am.ease.hyperbola)))
      world:append(node)
   end
   world:append(find_home())

   if bias == "right" then
      win.scene:prepend(am.translate(-278, -318) ^ world)
      win.scene:action(am.tween(win.scene"curtain", 1, {x2 = -268}, am.ease.bounce))

   elseif bias == "left" then
      win.scene:prepend(am.translate(-480, -318) ^ world)
      win.scene:action(am.tween(win.scene"curtain", 1, {x1 = 268}, am.ease.bounce))

   else
      error("invalid bias")
   end
   world:action(spawner)
end


-- determines when, where, and how often to spawn mobs.
function spawner(world)
   if math.random(25) == 1 then -- chance to spawn
      local spawn_position
      repeat
         -- ensure we spawn on an random tile along the map's edges
         local x, y = math.random(46), math.random(33)
         if math.random() < 0.5 then
            x = math.random(0, 1) * 46
         else
            y = math.random(0, 1) * 33
         end
         spawn_position = offset_to_hex(vec2(x, y))

         -- ensure that we spawn somewhere that is passable: mid-elevation
         local e = hash_retrieve(map, spawn_position)
      until e and e < 0.5 and e > -0.5

      local mob
      if bias == "right" then
         mob = am.translate(-278, -318) ^ am.circle(hex_to_pixel(spawn_position, vec2(11)), 4)

      elseif bias == "left" then
         mob = am.translate(-480, -318) ^ am.circle(hex_to_pixel(spawn_position, vec2(11)), 4)
      end
      world:append(mob"circle":action(coroutine.create(live)))
   end
end


-- This function is the coroutine that represents the life-cycle of a mob.
function live(mob)
   local dead = false

   local visited = {}; visited[mob.center] = true

   -- begin life
   repeat
      local neighbours = hex_neighbours(pixel_to_hex(mob.center, vec2(11)))
      local candidates = {}

      -- get list of candidates: hex positions to consider moving to.
      for _,h in pairs(neighbours) do

         local e = hash_retrieve(map, h)
         if e and e < 0.5 and e > -0.5 then
            if not hash_retrieve(visited, h) then
               table.insert(candidates, h)
            end
         end
      end

      -- choose where to move. manhattan distance closest to goal is chosen.
      local move = candidates[1]
      for _,h in pairs(candidates) do
         if math.distance(h, home.center) < math.distance(move, home.center) then
            move = h
         end
      end

      if not move then return true --error("can't find anywhere to move to")
      end -- bug

      local speed = (hash_retrieve(map, move)) ^ 2 + 0.5
      am.wait(am.tween(mob, speed, {center=hex_to_pixel(move, vec2(11))}))
      visited[move] = true
      if move == home.center then dead = true end
   until dead
   explosion(mob.center)
end

--
function init()
   local bg = am.rect(win.left, win.top, win.right, win.bottom, vec4(0.12, 0.3, 0.3, 1))
   :tag"curtain"

   -- -480, 300, -268, -300

   win.scene = am.group(bg)
   cartograph()
end

init()

