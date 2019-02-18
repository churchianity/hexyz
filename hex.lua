
----- [[ GENERALLY USEFUL FUNCTIONS ]] -----------------------------------------

-- rounds numbers. would've been cool to have math.round in lua.
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

----- [[ HEX CONSTANTS & UTILITY FUNCTIONS ]] ----------------------------------

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
    return hex + HEX_DIRECTIONS[(6 + (direction % 6)) % 6 + 1]
end

-- TODO rotations are different depending on the coordinate system you use.
-- implement this for cube/axial, and doubled.
function cube_rotate_left(hex)

end

function cube_rotate_right(hex)

end

-- rounds a float coordinate trio |x, y, z| to its nearest integer coordinate trio.
-- TODO make work with a table {x, y, z} and vec3(x, y, z)
function cube_round(x, y, z)
    local rx = round(x)
    local ry = round(y)
    local rz = round(z)

    local xdelta = math.abs(rx - x)
    local ydelta = math.abs(ry - y)
    local zdelta = math.abs(rz - z)

    if xdelta > ydelta and xdelta > zdelta then
        rx = -ry - rz
    elseif ydelta > zdelta then
        rx = -ry - rz
    else
        rz = -rx - ry
    end

    return vec3(rx, ry, rz)
end

----- [[ LAYOUT, ORIENTATION & COORDINATE CONVERSION  ]] -----------------------

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

    local x = (M[1][1] * cube.x + M[1][2] * cube.y) * layout.size.x
    local y = (M[2][1] * cube.x + M[2][2] * cube.y) * layout.size.y

    return vec2(x + layout.origin.x, y + layout.origin.y)
end

-- screen to hex
function pixel_to_cube(pix, layout)
    local W = layout.orientation.W

    local pix = (pix - layout.origin) / layout.size 

    local s = W[1][1] * pix.x + W[1][2] * pix.y
    local t = W[2][1] * pix.x + W[2][2] * pix.y

    return cube_round(s, t, -s - t) 
end

function hex_corner_offset(corner, layout)
    local angle = 2.0 * math.pi * layout.orientation.start_angle + corner / 6
    return vec2(layout.size.x * math.cos(angle), layout.size.y * math.sin(angle))
end

function hex_corners(hex, layout)
    local corners = {}
end

function cube_to_offset(cube)

end

function offset_to_cube(off)

end

function cube_to_doubled(cube)
    return vec2(cube.x, 2 * (-cube.x - cube.y) + cube.x)
end

function doubled_to_cube(dbl)
    return vec2(dbl.x, (dbl.y - dbl.x) / 2)
end

----- [[ MAP STORAGE & RETRIEVAL ]] --------------------------------------------
--[[
    TODO make all functions work regardless of layout. as it stands, they kind
    of do, just not always nicely.
  ]]

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

--[[ returns ordered hexagonal map of |radius| rings from |center|.
     the only difference between hex_spiral_map and hex_hexagonal_map is that
     hex_spiral_map is ordered, in a spiral path from the |center|.
  ]]
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

    for s = 0, width do
        for t = 0, height do
            map[vec2(s, t)] = true
        end
    end
    return map
end

-- returns unordered triangular map of |size|.
function triangular_map(size)
    local map = {}
    local mt = {__index={size=size}}

    setmetatable(map, mt)

    for s = 0, size do
        for t = size - s, size do
            map[vec2(s, t)] = true
        end
    end
    return map
end

-- returns unordered hexagonal map of |radius|.
function hexagonal_map(radius)
    local map = {}
    local mt = {__index={radius=radius}}

    setmetatable(map, mt)

    for s = -radius, radius do
        local t1 = math.max(-radius, -s - radius)
        local t2 = math.min(radius, -s + radius)

        for t = t1, t2 do
            map[vec2(s, t)] = true
        end
    end
    return map
end

-- returns unordered rectangular map of |width| and |height|.
function rectangular_map(width, height)
    local map = {}
    local mt = {__index={width=width, height=height}}

    setmetatable(map, mt)

    for s = 0, width do
        for t = 0, height do
            map[vec2(s, t - math.floor(s/2))] = true
        end
    end
    return map
end

----- [[ TESTS ]] --------------------------------------------------------------


