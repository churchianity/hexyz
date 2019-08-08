
-- Rounds Numbers.
local function round(n) return n % 1 >= 0.5 and math.ceil(n) or math.floor(n) end

--[[============================================================================
    -- HEX CONSTANTS AND UTILITY FUNCTIONS

]]
-- All Non-Diagonal Vector Directions from a Given Hex by Edge
HEX_DIRECTIONS = {vec2( 1 , -1), vec2( 1 ,  0), vec2(0 ,  1),
                  vec2(-1 ,  1), vec2(-1 ,  0), vec2(0 , -1)}

-- Return Hex Vector Direction via Integer Index |direction|
function hex_direction(direction)
   return HEX_DIRECTIONS[(direction % 6) % 6 + 1] end


-- Return Hexagon Adjacent to |hex| in Integer Index |direction|
function hex_neighbour(hex, direction)
   return hex + HEX_DIRECTIONS[(direction % 6) % 6 + 1] end


-- Collect All 6 Neighbours in a Table
function hex_neighbours(hex)
   local neighbours = {}
   for i = 1, 6 do
      table.insert(neighbours, hex_neighbour(hex, i))
   end
   return neighbours
end


-- Returns a vec2 Which is the Nearest |x, y| to Float Trio |x, y, z|
local function hex_round(x, y, z)
   local rx = round(x)
   local ry = round(y)
   local rz = round(z) or round(-x - y)

   local xdelta = math.abs(rx - x)
   local ydelta = math.abs(ry - y)
   local zdelta = math.abs(rz - z or round(-x - y))

   if xdelta > ydelta and xdelta > zdelta then
      rx = -ry - rz
   elseif ydelta > zdelta then
      ry = -rx - rz
   else
      rz = -rx - ry end
   return vec2(rx, ry)
end
--[[==========================================================================--
      -- ORIENTATION & LAYOUT

]]
-- Forward & Inverse Matrices used for the Flat Orientation
local FLAT = {M = mat2(3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5    ),
              W = mat2(2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0),
              angle = 0.0}

-- Forward & Inverse Matrices used for the Pointy Orientation
local POINTY = {M = mat2(3.0^0.5,   3.0^0.5/2.0,  0.0,  3.0/2.0),
                W = mat2(3.0^0.5/3.0,  -1.0/3.0,  0.0,  2.0/3.0),
                angle = 0.5}

-- Hex to Screen -- Orientation Must be Either POINTY or FLAT
function hex_to_pixel(hex, size, orientation_M)
   local M = orientation_M or FLAT.M

   local x = (M[1][1] * hex[1] + M[1][2] * hex[2]) * (size and size[1] or 11)
   local y = (M[2][1] * hex[1] + M[2][2] * hex[2]) * (size and size[2] or 11)

   return vec2(x, y)
end


-- Screen to Hex -- Orientation Must be Either POINTY or FLAT
function pixel_to_hex(pix, size, orientation_W)
   local W = orientation_W or FLAT.W

   local pix = pix / (size or vec2(11))

   local x = W[1][1] * pix[1] + W[1][2] * pix[2]
   local y = W[2][1] * pix[1] + W[2][2] * pix[2]

   return hex_round(x, y, -x - y)
end


-- TODO test, learn am.draw
function hex_corner_offset(corner, size, orientation_angle)
   local angle = 2.0 * math.pi * orientation_angle or FLAT.angle + corner / 6
   return vec2(size[1] * math.cos(angle), size[2] * math.sin(angle))
end


-- TODO test this thing
function hex_corners(hex, size, orientation)
   local corners = {}
   local center = hex_to_pixel(hex, size, orientation)
   for i = 0, 5 do
      local offset = hex_corner_offset(i, size, orientation)
      table.insert(corners, center + offset)
   end
   return corners
end


-- Offset Coordinates Look Nice / are Useful for UI-Implementations
function hex_to_offset(hex)
   return vec2(hex[1], -hex[1] - hex[2] + (hex[1] + (hex[1] % 2)) / 2) end


-- Back to Cube Coordinates
function offset_to_hex(off)
   return vec2(off[1], off[2] - math.floor((off[1] - 1 * (off[1] % 2))) / 2) end

--[[============================================================================
    -- MAPS & STORAGE

]]
-- Returns Ordered Ring-Shaped Map of |radius| from |center|
function ring_map(center, radius)
   local map = {}

   local walk = center + HEX_DIRECTIONS[6] * radius

   for i = 1, 6 do
      for j = 1, radius do
         table.insert(map, walk)
         walk = hex_neighbour(walk, i)
      end
   end
   setmetatable(map, {__index={center=center, radius=radius}})
   return map
end


-- Returns Ordered Spiral Hexagonal Map of |radius| Rings from |center|
function spiral_map(center, radius)
   local map = {center}

   for i = 1, radius do
      table.append(map, ring_map(center, i))
   end
   setmetatable(map, {__index={center=center, radius=radius}})
   return map
end


-- Returns Unordered Parallelogram-Shaped Map of |width| and |height| with Simplex Noise
function parallelogram_map(width, height, seed)
   local seed = seed or math.random(width * height)

   local map = {}
   for i = 0, width do
      map[i] = {}
      for j = 0, height do

         -- Calculate Noise
         local idelta = i / width
         local jdelta = j / height
         local noise = 0

         for oct = 1, 6 do
            local f = 1/4^oct
            local l = 2^oct
            local pos = vec2(idelta + seed * width, jdelta + seed * height)
            noise = noise + f * math.simplex(pos * l)
         end
         map[i][j] = noise
      end
   end
   setmetatable(map, {__index={width=width, height=height, seed=seed}})
   return map
end


-- Returns Unordered Triangular (Equilateral) Map of |size| with Simplex Noise
function triangular_map(size, seed)
   local seed = seed or math.random(size * math.cos(size) / 2)

   local map = {}
   for i = 0, size do
      map[i] = {}
      for j = size - i, size do

         -- Generate Noise
         local idelta = i / size
         local jdelta = j / size
         local noise = 0

         for oct = 1, 6 do
            local f = 1/3^oct
            local l = 2^oct
            local pos = vec2(idelta + seed * size, jdelta + seed * size)
            noise = noise + f * math.simplex(pos * l)
         end
         map[i][j] = noise
      end
   end
   setmetatable(map, {__index={size=size, seed=seed}})
   return map
end


-- Returns Unordered Hexagonal Map of |radius| with Simplex Noise
function hexagonal_map(radius, seed)
   local seed = seed or math.random(radius * 2 * math.pi)

   local map = {}
   for i = -radius, radius do
      map[i] = {}

      local j1 = math.max(-radius, -i - radius)
      local j2 = math.min(radius, -i + radius)

      for j = j1, j2 do

         -- Calculate Noise
         local idelta = i / radius
         local jdelta = j / radius
         local noise = 0

         for oct = 1, 6 do
            local f = 2/3^oct
            local l = 2^oct
            local pos = vec2(idelta + seed * radius, jdelta + seed * radius)

            noise = noise + f * math.simplex(pos * l)
         end
         map[i][j] = noise
      end
   end
   setmetatable(map, {__index={radius=radius, seed=seed}})
   return map
end


-- Returns Unordered Rectangular Map of |width| and |height| with Simplex Noise
function rectangular_map(width, height, seed)
   local seed = seed or math.random(width * height)

   local map = {}
   for i = 0, width do
      map[i] = {}
      for j = 0, height do

         -- Begin to Calculate Noise
         local idelta = i / width
         local jdelta = j / height
         local noise = 0

         for oct = 1, 6 do
            local f = 2/3^oct
            local l = 2^oct
            local pos = vec2(idelta + seed * width, jdelta + seed * height)
            noise = noise + f * math.simplex(pos * l)
         end
         j = j - math.floor(i/2) -- this is what makes it rectangular

         -- store two dimensions as a single number
         map[i][j] = noise
      end
   end
   setmetatable(map, {__index={width=width, height=height, seed=seed}})
   return map
end

--[[==========================================================================--
    ----- PATHFINDING -----
============================================================================]]--

-- big ol' TODO



