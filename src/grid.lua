
require "colors"

WORLD_GRID_DIMENSIONS = vec2(46, 32)
CELL_SIZE = 20
local world_grid_map

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
      return COLORS.BLUE_STONE{ a = (elevation + 1.4) / 2 + 0.2 }

   elseif elevation < 0 then -- med-low elevation : passable
      return COLORS.MYRTLE{ a = (elevation + 1.8) / 2 + 0.2 }

   elseif elevation < 0.5 then -- med-high elevation : passable
      return COLORS.BROWN_POD{ a = (elevation + 1.6) / 2 + 0.2 }

   elseif elevation < 1 then     -- highest elevation : impassable
      return COLORS.BOTTLE_GREEN{ a = (elevation + 1.0) / 2 + 0.2 }
   end
end

function worldspace_coordinate_offset()
    return vec2(-hex_height(CELL_SIZE))
end

function random_map(seed)
   world_grid_map = rectangular_map(WORLD_GRID_DIMENSIONS.x, WORLD_GRID_DIMENSIONS.y, seed);
   math.randomseed(world_grid_map.seed)
   local world = am.translate(worldspace_coordinate_offset()) ^ am.group(am.circle(vec2(0), 32, COLORS.WHITE)):tag"world"

   for i,_ in pairs(world_grid_map) do
      for j,elevation in pairs(world_grid_map[i]) do

         -- subtly shade map edges
         local off = hex_to_offset(vec2(i, j))
         local mask = vec4(0, 0, 0, math.max(((off.x - WORLD_GRID_DIMENSIONS.x/2) / WORLD_GRID_DIMENSIONS.x) ^ 2,
                                            ((-off.y - WORLD_GRID_DIMENSIONS.y/2) / WORLD_GRID_DIMENSIONS.y) ^ 2))
         local color = color_at(elevation) - mask

         local node = am.circle(hex_to_pixel(vec2(i, j)), CELL_SIZE, vec4(0), 6)
         :action(am.tween(2, { color=color }, am.ease.out(am.ease.hyperbola)))

         world:append(node)
      end
   end
   --world:append(find_home(2))
   --world:action(spawner)
   return world:tag"world"
end


