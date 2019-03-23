
-- Rounds Numbers.
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

--[[============================================================================
    ----- HEX CONSTANTS AND UTILITY FUNCTIONS -----
============================================================================]]--

-- Hex Equality - Meant to Operate on two Amulet Vectors (vec2)
function hex_equals(a, b) return a[1] == b[1] and a[2] == b[2] end
function hex_not_equals(a, b) return not hex_equals(a, b) end


-- All Possible Vector Directions from a Given Hex by Edge
local HEX_DIRECTIONS = {vec2( 0 ,  1), vec2( 1 ,  0), vec2( 1 , -1),
                        vec2( 0 , -1), vec2(-1 ,  0), vec2(-1 ,  1)}

-- Return Hex Vector Direction via Integer Index |direction|.
function hex_direction(direction)
    return HEX_DIRECTIONS[(direction % 6) % 6 + 1]
end


-- Return Hexagon Adjacent to |hex| in Integer Index |direction|.
function hex_neighbour(hex, direction)
    return hex + HEX_DIRECTIONS[(direction % 6) % 6 + 1]
end


-- Return Hex 60deg away to the Left; Counter-Clockwise
function hex_rotate_left(hex)
    return vec2(hex.x + hex.y, -hex.x)
end


-- Return Hex 60deg away to the Right; Clockwise
function hex_rotate_right(hex)
    return vec2(-hex.y, hex.x + hex.y)
end


-- NOT a General 3D Vector Round - Only Returns a vec2!
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
        rz = -rx - ry
    end
    return vec2(rx, ry)
end

--[[==========================================================================--
    ----- ORIENTATION & LAYOUT -----
============================================================================]]--


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

    local x = (M[1][1] * hex[1] + M[1][2] * hex[2]) * size[1]
    local y = (M[2][1] * hex[1] + M[2][2] * hex[2]) * size[2]

    return vec2(x, y)
end


-- Screen to Hex -- Orientation Must be Either POINTY or FLAT
function pixel_to_hex(pix, size, orientation_W)
    local W = orientation_W or FLAT.W

    local pix = pix / size

    local x = W[1][1] * pix[1] + W[1][2] * pix[2]
    local y = W[2][1] * pix[1] + W[2][2] * pix[2]

    return hex_round(x, y, -x - y)
end


-- TODO test, learn am.draw
function hex_corner_offset(corner, size, orientation_angle)
    local angle = 2.0 * math.pi * orientation_angle or FLAT.angle + corner / 6
    return vec2(size[1] * math.cos(angle),
                size[2] * math.sin(angle))
end


-- TODO this thing
function hex_corners(hex, size, orientation)
    local corners = {}
end


-- Offset Coordinates are Useful for UI-Implementations
function hex_to_offset(hex)
    return vec2(hex[1], -hex[1] - hex[2] + (hex[1] + (hex[1] % 2)) / 2)
end


-- back to cube coordinates
function offset_to_hex(off)
    return vec2(off[1], off[2] - off[1] * (off[1] % 2) / 2)
end

--[[============================================================================
    ----- MAPS & STORAGE -----

  You are not to draw using the coordinates stored in your map.
  You are to draw using the hex_to_pixel of those coordinates.

  If you wish to draw a hexagon to the screen, you must first use hex_to_pixel
  to retrieve the center of the hexagon on each set of cube coordinates stored
  in your map. Then, depending on how you are going to draw, either call
  am.circle with |sides| = 6, or gather the vertices with hex_corners and
  use am.draw - TODO, haven't used am.draw yet.

  Maps have metatables containing information about their dimensions, and
  seed (if applicable), so you can retrieve information about maps after they
  are created.

    ----- NOISE -----
  To simplify terrain generation, unordered, hash-like maps automatically
  calculate and store seeded simplex noise as their values. You can provide
  a seed if you wish. The default is a randomized seed.

  TODO Pointy Hex testing and support.

============================================================================]]--


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
            map[vec2(i, j)] = noise -- Straightforward Iteration Produces a Parallelogram
        end
    end
    setmetatable(map, {__index={width=width, height=height, seed=seed}})
    return map
end


-- Returns Unordered Triangular Map of |size| with Simplex Noise
function triangular_map(size, seed)
    local seed = seed or math.random(size)

    local map = {}
    for i = 0, size do
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

            map[vec2(i, j)] = noise
        end
    end
    setmetatable(map, {__index={size=size, seed=seed}})
    return map
end


-- Returns Unordered Hexagonal Map of |radius| with Simplex Noise
function hexagonal_map(radius, seed)
    local seed = seed or math.random(radius * 2 + 1)

    local map = {}
    for i = -radius, radius do
        local j1 = math.max(-radius, -i - radius)
        local j2 = math.min(radius, -i + radius)

        for j = j1, j2 do

            -- Calculate Noise
            local idelta = i / radius
            local jdelta = j / radius
            local noise = 0

            for oct = 1, 6 do

                local f = 2/3^oct -- NOTE, for some reason, I found 2/3 produces better looking noise maps. As far as I am aware, this is weird.
                local l = 2^oct
                local pos = vec2(idelta + seed * radius, jdelta + seed * radius)

                noise = noise + f * math.simplex(pos * l)
            end
            map[vec2(i, j)] = noise
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
        for j = 0, height do

            -- Calculate Noise
            local idelta = i / width
            local jdelta = j / height
            local noise = 0

            for oct = 1, 6 do

                local f = 2/3^oct
                local l = 2^oct
                local pos = vec2(idelta + seed * width, jdelta + seed * height)

                noise = noise + f * math.simplex(pos * l)
            end
            -- Store Hex in the Map Paired with its Associated Noise Value
            map[vec2(i, j - math.floor(i/2))] = noise
        end
    end
    setmetatable(map, {__index={width=width, height=height, seed=seed}})
    return map
end

--[[==========================================================================--
    ----- PATHFINDING -----
============================================================================]]--


-- first try
function search(map, start)
    local neighbours
    for i = 1, 6 do
        neighbours[#neighbours + 1] = hex_neighbour(start, i)
    end
end









--
function breadth_first_search(map, start)
    local frontier = {start}

    local visited  = {start = true}

    while next(frontier) ~= nil do
        local current = next(frontier)
        local neighbours
        for i = 1, 6 do
            neighbours[#neighnours + 1] = hex_neighbour(current, i)
        end
        for _,n in neighbours do
            if visited[n] ~= true then
                visited[n] = true
            end
        end
    end
end


