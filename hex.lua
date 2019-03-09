
--[[============================================================================
                    ----- GENERALLY USEFUL FUNCTIONS -----
============================================================================]]--

-- rounds numbers. would've been cool to have math.round in lua.
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

--[[============================================================================
                ----- HEX CONSTANTS AND UTILITY FUNCTIONS -----
============================================================================]]--

-- all possible vector directions from a given hex by edge
local CUBE_DIRECTIONS = {vec2( 0 ,  1),
                         vec2( 1 ,  0),
                         vec2( 1 , -1),
                         vec2( 0 , -1),
                         vec2(-1 ,  0),
                         vec2(-1 ,  1)}

-- return hex vector direction via integer index |direction|.
function cube_direction(direction)
    return CUBE_DIRECTIONS[(direction % 6) % 6 + 1]
end

-- return hexagon adjacent to |hex| in integer index |direction|.
function cube_neighbour(hex, direction)
    return hex + CUBE_DIRECTIONS[(direction % 6) % 6 + 1]
end

-- return cube coords at location 60deg away to the left; counter-clockwise
function cube_rotate_left(hex)
    return vec2(hex.x + hex.y, -hex.x)
end

-- return cube coords at location 60deg away to the right; clockwise
function cube_rotate_right(hex)
    return vec2(-hex.y, hex.x + hex.y)
end

-- rounds a float coordinate trio |x, y, z| to nearest integer coordinate trio
local function cube_round(x, y, z)
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

--[[============================================================================
                ----- ORIENTATION & LAYOUT -----
============================================================================]]--

-- forward & inverse matrices used for the flat orientation
local FLAT = {M = mat2(3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5    ),
              W = mat2(2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0),
              start_angle = 0.0}

-- forward & inverse matrices used for the pointy orientation
local POINTY = {M = mat2(3.0^0.5,   3.0^0.5/2.0,  0.0,  3.0/2.0),
                W = mat2(3.0^0.5/3.0,  -1.0/3.0,  0.0,  2.0/3.0),
                start_angle = 0.5}

-- stores layout: information that does not pertain to map shape
function layout(origin, size, orientation)
    return {origin      = origin      or vec2(0),
            size        = size        or vec2(11),
            orientation = orientation or FLAT}
end

-- hex to screen
function cube_to_pixel(cube, layout)
    local M = layout.orientation.M

    local x = (M[1][1] * cube[1] + M[1][2] * cube[2]) * layout.size[1]
    local y = (M[2][1] * cube[1] + M[2][2] * cube[2]) * layout.size[2]

    return vec2(x + layout.origin[1], y + layout.origin[2])
end

-- screen to hex
function pixel_to_cube(pix, layout)
    local W = layout.orientation.W

    local pix = (pix - layout.origin) / layout.size

    local s = W[1][1] * pix[1] + W[1][2] * pix[2]
    local t = W[2][1] * pix[1] + W[2][2] * pix[2]

    return cube_round(s, t, -s - t)
end

-- TODO test, learn am.draw
function hex_corner_offset(corner, layout)
    local angle = 2.0 * math.pi * layout.orientation.start_angle + corner / 6
    return vec2(layout.size[1] * math.cos(angle),
                layout.size[2] * math.sin(angle))
end

-- TODO this thing
function hex_corners(hex, layout)
    local corners = {}
end

-- offset coordinates are prettier to look at
function cube_to_offset(cube)
    return vec2(cube[1], -cube[1] - cube[2] + (cube[1] + (cube[1] % 2)) / 2)
end

-- back to cube coordinates
function offset_to_cube(off)
    return vec2(off[1], off[2] - off[1] * (off[1] % 2) / 2)
end

--[[============================================================================
    ----- MAPS & STORAGE -----
  MAPS STORE CUBE COORDINATES. MAPS STORE CUBE COORDINATES. MAPS STORE CUBE COOR

  This means, you are not to draw using the coordinates stored in your map.
  You are to draw using the cube_to_pixel of those coordinates.

  If you wish to draw a hexagon to the screen, you must first use cube_to_pixel
  to retrieve the center of the hexagon on each set of cube coordinates stored
  in your map. Then, depending on how you are going to draw, either call
  am.circle with |sides| = 6, or gather the vertices with hex_corners and
  use am.draw - TODO, haven't used am.draw yet.

  Information about the maps' dimensions are stored in a metatable, so you can
  retrieve details about maps after they are created.

    ----- NOISE -----
  To simplify terrain generation, unordered, hash-like maps automatically
  calculate and store perlin noise as their values. You can modify the nature
  of the noise by providing different |frequencies| as a tables of values, for
  example: {1, 2, 4, 8} or {1, 0.5, 0.25, 0.125}. These just increase the
  complexity of the curvature of the noise. The default is {1}.

    ----- TODO -----
  TODO make all functions work regardless of layout. as it stands, they kind
  of do, just not always nicely.

============================================================================]]--
----- ORDERED MAPS -----

-- returns ordered ring-shaped map of |radius| from |center|.
function ring_map(center, radius)
    local map = {}
    local mt = {__index={center=center, radius=radius}}

    setmetatable(map, mt)

    local walk = center + CUBE_DIRECTIONS[6] * radius

    for i = 1, 6 do
        for j = 1, radius do
            table.insert(map, walk)
            walk = cube_neighbour(walk, i)
        end
    end
    return map
end

-- returns ordered hexagonal map of |radius| rings from |center|.
-- the only difference between spiral_map and hexagonal_map is that
-- spiral_map is ordered, in a spiral path from the |center|.

function spiral_map(center, radius)
    local map = {center}
    local mt = {__index={center=center, radius=radius}}

    setmetatable(map, mt)

    for i = 1, radius do
        table.append(map, ring_map(center, i))
    end
    return map
end

----- UNORDERED, HASH-LIKE MAPS -----

-- returns unordered parallelogram-shaped map of |width| and |height| with perlin noise
function parallelogram_map(width, height)
    local map = {}
    local mt = {__index={width=width, height=height}}

    setmetatable(map, mt)

    for i = 0, width do
        for j = 0, height do
            map[vec2(i, j)] = true
        end
    end
    return map
end

-- returns unordered triangular map of |size| with perlin noise
function triangular_map(size)
    local map = {}
    local mt = {__index={size=size}}

    setmetatable(map, mt)

    for i = 0, size do
        for j = size - s, size do
            map[vec2(i, j)] = true
        end
    end
    return map
end

-- returns unordered hexagonal map of |radius| with perlin noise
function hexagonal_map(radius)
    local map = {}
    local mt = {__index={radius=radius}}

    setmetatable(map, mt)

    for i = -radius, radius do
        local j1 = math.max(-radius, -i - radius)
        local j2 = math.min(radius, -i + radius)

        for j = j1, j2 do
            map[vec2(i, j)] = true
        end
    end
    return map
end

-- returns unordered rectangular map of |width| and |height| with perlin noise
function rectangular_map(width, height, frequencies)

    local map = {}
    local mt = {__index={width=width, height=height}}
    local frequencies = frequencies or {1}

    setmetatable(map, mt)

    for i = 0, width do
        for j = 0, height do

            -- calculate noise
            local idelta = assert(i / width, "width must be greater than 0")
            local jdelta = assert(j / height, "height must be greater than 0")
            local noise = 0

            for _,freq in pairs(frequencies) do
                noise = noise + 1/freq * math.perlin(vec2(freq * idelta,
                                                          freq * jdelta))
            end

            -- this is what makes it a rectangle
            local hex = vec2(i, j - math.floor(i/2))

            -- store hex in the map paired with its associated noise value
            map[hex] = noise
        end
    end
    return map
end

--[[============================================================================
                             ----- NOISE -----
============================================================================]]--

function simplex_map(frequency, exponent, width, height)
    local map = {}

    for i = 0, height do
        for j = 0, width do
            local idelta = i/width - 0.5
            local jdelta = j/height - 0.5
            map[vec2(i, j)] = math.simplex(idelta, jdelta)
        end
    end
end







--[[============================================================================
                         ----- PATHFINDING -----
============================================================================]]--








--[[============================================================================
                         ----- TESTS -----
============================================================================]]--

function test_all()
    print("it works trust me")
end

