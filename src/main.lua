
require"hexyz"

math.randomseed(os.time()); math.random(); math.random(); math.random()
--[[============================================================================


]]
--
win = am.window
{  -- Base Resolution = 3/4 * WXGA standard 16:10 -- 960px, 600px
   width = 1280 * 3/4, height = 800 * 3/4,
   clear_color = vec4(0.08, 0.08, 0.11, 1)
}


local map
local home
local spawn_chance = 25

--[[============================================================================


]]
-- ensure home-base is somewhat of an open area.
function find_home(preferred_radius)
   home = spiral_map(vec2(23, 4), preferred_radius or 2)
   local home_node = am.group()

   repeat
      local happy = true

      for i,h in pairs(home) do
         local elevation = map[h.x][h.y]

         if not elevation then -- hex not in map
         elseif elevation > 0.5 or elevation < -0.5 then
            happy = false

         elseif not happy then
            home = spiral_map(h, preferred_radius or 1)
            home_node = am.group()

         else
            local center = hex_to_pixel(h)
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
   if elevation < -0.5 then -- lowest elevation : impassable
      return vec4(0.10, 0.30, 0.40, (elevation + 1.4) / 2 + 0.2)

   elseif elevation < 0 then -- med-low elevation : passable
      return vec4(0.10, 0.25, 0.10, (elevation + 1.8) / 2 + 0.2)

   elseif elevation < 0.5 then -- med-high elevation : passable
      return vec4(0.25, 0.20, 0.10, (elevation + 1.6) / 2 + 0.2)

   elseif elevation < 1 then     -- highest elevation : impassable
      return vec4(0.15, 0.30, 0.20, (elevation + 1.0) / 2 + 0.2)
   end
end


--
function random_map(seed)
   map = rectangular_map(46, 33, seed); math.randomseed(map.seed)
   local world = am.translate(vec2(-278, -318)) ^ am.group():tag"world"

   for i,_ in pairs(map) do
      for j,elevation in pairs(map[i]) do

         -- subtly shade map edges
         local off = hex_to_offset(vec2(i, j))
         local mask = vec4(0, 0, 0, math.max(((off.x - 23.5) / 46) ^ 2,
                                            ((-off.y - 16.5) / 32) ^ 2))
         local color = color_at(elevation) - mask

         local node = am.circle(hex_to_pixel(vec2(i, j)), 11, vec4(0), 6)
         :action(am.tween(2, {color=color}, am.ease.out(am.ease.hyperbola)))
         world:append(node)
      end
   end
   world:append(find_home(2))
   world:action(spawner)
   return world:tag"world"
end


-- determines when, where, and how often to spawn mobs.
function spawner(world)
   if math.random(spawn_chance) == 1 then -- chance to spawn
      local spawn_position
      repeat
         -- ensure we spawn on an random tile along the map's edges
         local x,y = math.random(46), math.random(33)
         if math.random() < 0.5 then
            x = math.random(0, 1) * 46
         else
            y = math.random(0, 1) * 33
         end
         spawn_position = offset_to_hex(vec2(x, y))

         -- ensure that we spawn somewhere that is passable: mid-elevation
         local e = map[spawn_position.x][spawn_position.y]
      until e and e < 0.5 and e > -0.5

      local mob = am.translate(-278, -318) ^ am.circle(hex_to_pixel(spawn_position), 4)
      world:append(mob"circle":action(coroutine.create(live)))
   end
end


-- this function is the coroutine that represents the life-cycle of a mob.
function live(mob)
   local dead = false

   local visited = {}
   visited[mob.center.x] = {}; visited[mob.center.x][mob.center.y] = true

   -- begin life
   repeat
      local neighbours = hex_neighbours(pixel_to_hex(mob.center))
      local candidates = {}

      -- get list of candidates: hex positions to consider moving to.
      for _,h in pairs(neighbours) do

         local e
         if map[h.x] then
            e = map[h.x][h.y]
         end

         if e and e < 0.5 and e > -0.5 then
            if visited[h.x] then
               if not visited[h.x][h.y] then
                  table.insert(candidates, h)
               end
            else
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

      if not move then print("can't find anywhere to move to"); return
      end -- bug

      local speed = map[move.x][move.y] ^ 2 + 0.5
      am.wait(am.tween(mob, speed, {center=hex_to_pixel(move)}))
      visited[move.x] = {}; visited[move.x][move.y] = true
      if move == home.center then dead = true end
   until dead
   win.scene:remove(mob)
end


-- POLL MOUSE
function poll_mouse()
   if win:mouse_position().x > -268 then -- mouse is inside game map
      -- get info about mouse position
      local hex = pixel_to_hex(win:mouse_position() - vec2(-278, -318))
      local off = hex_to_offset(hex)

      -- check if cursor location outside of map bounds
      if off.x <= 1 or -off.y <= 1 or off.x >= 46 or -off.y >= 32 then
         win.scene"coords".text = ""

      else
         if win:mouse_down"left" then -- check if mouse clicked
            if map[hex.x][hex.y] <= -0.5 or map[hex.x][hex.y] >= 0.5 then

            else
               map[hex.x][hex.y] = 2
               win.scene"world":append(am.circle(hex_to_pixel(hex), 11, vec4(0, 0, 0, 1), 6))
            end
         end
         win.scene"coords".text = string.format("%2d,%2d", off.x, -off.y)
         win.scene"selected".center = hex_to_pixel(hex) + vec2(-278, -318)
      end
   else -- mouse is over background bar, (or outside window!!!!)
      if win:key_pressed"escape" then
         init()
      end
   end
end


--
function update_score()
   win.scene"score".text = string.format("SCORE: %.2f", am.current_time())
end


function update_mobs()


end



--
function button(x, y)
   local color = (x + y) % 2 == 0 and vec4(0.4, 0.4, 0.5, 1) or vec4(0.5, 0.4, 0.4, 1)
   return am.translate(x * 80, y * 80) ^ am.rect(-40, 40, 40, -40, color)
end


-- GAME INITIALIZATION FUNCTION
function game_init()
   local score = am.translate(-264, 290) ^ am.text("", "left"):tag"score"
   local coords = am.translate(440, 290) ^ am.text(""):tag"coords"
   local selected = am.circle(vec2(win.left, win.top), 11, vec4(0.4), 6):tag"selected"
   local bg = am.rect(win.left, win.top, win.right, win.bottom, vec4(0.12, 0.3, 0.3, 1)):tag"curtain"

   local buttons = am.translate(-500, -300) ^ am.group()
   for i = 1, 2 do
      for j = 1, 6 do
         buttons:append(button(i, j))
      end
   end

   local main_scene = am.group{random_map(9), bg, buttons, score, coords, selected}
   :action(am.series
   {
      am.tween(bg, 0.8, {x2 = -268}, am.ease.bounce), -- INTRO TRANSITION

      function(scene)   -- MAIN ACTION
         update_score()
         -- update mobs
         -- update towers
         -- update environment
         poll_mouse() -- check if player did anything
      end
   })
   win.scene = main_scene
end


-- TITLE SCREEN
function init()
   local map = hexagonal_map(15, 9)
   local backdrop = am.group()

   for i,_ in pairs(map) do
      for j,e in pairs(map[i]) do
         backdrop:append(am.circle(hex_to_pixel(vec2(i, j)), 11, color_at(e), 6))
      end
   end

   local title_text = am.group
   {
      am.translate(0, 200) ^ am.scale(5) ^ am.text("hexyz", vec4(0.8, 0.8, 0.7, 1), "right"),
      am.translate(0, 130) ^ am.scale(4) ^ am.text("a tower defense", vec4(0.8, 0.8, 0.7, 1)),
      am.circle(vec2(0), 100, vec4(0.6), 6):tag"b", am.scale(4) ^ am.text("START", vec4(0, 0, 0, 1))
   }

   win.scene = am.group
   {
      backdrop,
      title_text
   }
   :action(function(s)
      local mouse = win:mouse_position()
      if math.length(mouse) < 100 then
         s"b":action(am.series
         {
            am.tween(0.1, {color = vec4(0.8, 0.8, 0.7, 1)}),
            am.tween(0.1, {color = vec4(0.6)})
         })
         if win:mouse_pressed"left" then
            game_init()
         end
      end
   end)
end

init()
noglobals()

