
--[[============================================================================
                    ----- GENERALLY USEFUL FUNCTIONS -----
==============================================================================]]

-- rounds numbers. would've been cool to have math.round in lua.
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

--[[============================================================================
                ----- HEX CONSTANTS AND UTILITY FUNCTIONS -----
==============================================================================]]

-- all possible vector directions from a given hex by edge
local CUBE_DIRECTIONS = {vec2( 1 ,  0),
                         vec2( 1 , -1),
                         vec2( 0 , -1),
                         vec2(-1 ,  0),
                         vec2(-1 ,  1),
                         vec2( 0 ,  1)}

-- return hex vector direction via integer index |direction|.
function cube_direction(direction)
    return CUBE_DIRECTIONS[(6 + (direction % 6)) % 6 + 1]
end

-- return hexagon adjacent to |hex| in integer index |direction|.
function cube_neighbour(hex, direction)
    return hex + CUBE_DIRECTIONS[(6 + (direction % 6)) % 6 + 1]
end

-- TODO cube rotations
function cube_rotate_left(hex)
end

function cube_rotate_right(hex)
end

-- rounds a float coordinate trio |x, y, z| to nearest integer coordinate trio
-- only ever used internally; no need to use a vector. 
local function cube_round(x, y, z)
    local rx = round(x)
    local ry = round(y)
    local rz = round(z) or round(-x - y)

    local xdelta = math.abs(rx - x)
    local ydelta = math.abs(ry - y)
    local zdelta = math.abs(rz - z)

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
==============================================================================]]

-- forward & inverse matrices used for the flat orientation.
local FLAT = {M = mat2(3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5    ),
              W = mat2(2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0),
              start_angle = 0.0}

-- forward & inverse matrices used for the pointy orientation.
local POINTY = {M = mat2(3.0^0.5,  3.0^0.5/2.0,  0.0,   3.0/2.0),
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

--
function cube_to_offset(cube)
    return vec2(cube[1], -cube[1] - cube[2] + (cube[1] + (cube[1] % 2)) / 2)
end

-- 
function offset_to_cube(off)
    return vec2(off[1], off[2] - off[1] * (off[1] % 2) / 2)
end

--[[============================================================================
                         ----- MAPS & STORAGE -----
==============================================================================]]

-- information about the maps' dimensions are stored in a metatable, so you can
-- retrieve details about arbitrary maps after they are created.

-- TODO make all functions work regardless of layout. as it stands, they kind
-- of do, just not always nicely.

-- returns ordered ring-shaped map of |radius| from |center|.
function ring_map(center, radius)
    local map = {}
    local mt = {__index={center=center, radius=radius}}

    setmetatable(map, mt)

    local walk = center + HEX_DIRECTIONS[6] * radius

    for i = 1, 6 do
        for j = 1, radius do
            table.insert(map, walk)
            walk = hex_neighbour(walk, i)
        end
    end
    return map
end

-- returns ordered hexagonal map of |radius| rings from |center|.
-- the only difference between hex_spiral_map and hex_hexagonal_map is that
-- hex_spiral_map is ordered, in a spiral path from the |center|.
function spiral_map(center, radius)
    local map = {center}
    local mt = {__index={center=center, radius=radius}}

    setmetatable(map, mt)

    for i = 1, radius do
        table.append(map, hex_ring_map(center, i))
    end
    return map
end

-- returns unordered parallelogram-shaped map of |width| and |height|.
function parallelogram_map(width, height)
    local map = {}
    local mt = {__index={width=width, height=height}}

    setmetatable(map, mt)

    for i = 0, width do
        for j = 0, height do
            map[vec2(i, -j)] = true
        end
    end
    return map
end

-- returns unordered triangular map of |size|.
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

-- returns unordered hexagonal map of |radius|.
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

-- returns unordered rectangular map of |width| and |height|.
function rectangular_map(width, height)
    local map = {}
    local mt = {__index={width=width, height=height}}

    setmetatable(map, mt)

    for i = 0, width do
        for j = 0, height do
            map[vec2(i, -j - math.floor(i/2))] = true
        end
    end
    return map
end

--[[============================================================================
                         ----- TESTS -----
==============================================================================]]

function test_all()
    print("it works trust me")
end

