
require"hexyz"

math.randomseed(os.time())

local win = am.window
{
   -- Base Resolution = 3/4 * WXGA standard 16:10
   width = 1280 * 3/4, -- 960px
   height = 800 * 3/4, -- 600px
}

local map
local world
local home
local home_node


function find_home()
   home = spiral_map(vec2(23, 4), 2)
   home_node = am.group()
   repeat
      local happy = true

      for i,h in pairs(home) do

         local elevation = hash_retrieve(map, h)

         if not elevation then -- hex not in map
         elseif elevation > 0.5 or elevation < -0.5 then
            happy = false

         elseif not happy then
            home = spiral_map(h, 2)
            home_node = am.group()

         else
            local center = hex_to_pixel(h, vec2(11))
            local color = vec4(0.5)
            local node = am.circle(center, 4, color, 4)
            home_node:append(node)
         end
      end
   until happy
   return home_node
end


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


function draw_(map)
   world = am.group()

   for hex,elevation in pairs(map) do
      local off = hex_to_offset(hex)
      local mask = vec4(0, 0, 0, math.max(((off.x - 23.5) / 46) ^ 2,
                                         ((-off.y - 16.5) / 32) ^ 2))
      local color = color_at(elevation) - mask
      local node = am.circle(hex_to_pixel(hex, vec2(11)), 11, vec4(0), 6)
      :action(am.tween(5, {color = color}, am.ease.out(am.ease.hyperbola)))
      world:append(node:tag(tostring(hex)))
   end

   world:append(find_home())

   return am.translate(-278, -318) ^ world:tag"world"
end


function spawner(world)

   if math.random(10) == 1 then -- chance to spawn
      local spawn_position
      repeat
         -- ensure we spawn on an random tile along the map's edges
         local x, y = math.random(46), math.random(33)
         if math.random() < 0.5 then
            x = math.random(0, 1) * 47
         else
            y = math.random(0, 1) * 33
         end
         spawn_position = offset_to_hex(vec2(x, y))

         -- ensure that we spawn somewhere that is passable: mid-elevation
         local e = hash_retrieve(map, spawn_position)
      until e and e < 0.5 and e > -0.5

      local mob = am.circle(hex_to_pixel(spawn_position, vec2(11)), 4, vec4(1), 6)
      :action(coroutine.create(function(mob)
         local dead = false
         repeat
            local neighbours = hex_neighbours(pixel_to_hex(mob.center, vec2(11)))
            local candidates = {}
            for _,h in pairs(neighbours) do

               local e = hash_retrieve(map, h)
               if e and e < 0.5 and e > -0.5 then
                  table.insert(candidates, h)
               end
            end
            local move = candidates[math.random(#candidates)]
            am.wait(am.tween(mob, 1, {center=hex_to_pixel(move, vec2(11))}))
         until dead
      end))
      world:append(mob)
   end
end


function game_init(seed)
   local bg = am.rect(-480, 300, -268, -300, vec4(0.12, 0.3, 0.3, 1))
   map = rectangular_map(46, 33)

   math.randomseed(map.seed)
   win.scene = am.group(draw_(map):action(spawner), bg)
end


--
game_init()

