----- [[ HEX GEOMETRY LIBRARY FOR AMULET/LUA ]] --------------------------------
--[[                                                     author@churchianity.ca
        
        -- resources used to develop this library and for which i am grateful
    https://redblobgames.com/grid/hexagons    - simply amazing. 
    http://amulet.xyz/doc                     - amulet documentation
    TODO that place that had the inner circle/outer circle ratio?? 

  ]]

----- [[ GENERALLY USEFUL FUNCTIONS ]] -----------------------------------------

-- rounds numbers. would've been cool to have math.round in lua.  
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

----- [[ HEX CONSTANTS & UTILITIES ]] ------------------------------------------

-- all possible vector directions from a given hex
local HEX_DIRECTIONS = {vec3( 1 , -1,  0), 
                        vec3( 1 ,  0, -1), 
                        vec3( 0 ,  1, -1),
                        vec3(-1 ,  1,  0), 
                        vec3(-1 ,  0,  1), 
                        vec3( 0 , -1,  1)}

function hex_direction(direction)
    return HEX_DIRECTIONS[direction]
end

function hex_neighbour(hex, direction)
    return hex + HEX_DIRECTIONS[direction]
end

-- without this, pixel_to_hex() returns a fractional coordinate pair.
function hex_round(s, t)
    local rs = round(s)
    local rt = round(t)
    local rz = round(-s - t)

    local sdelta = math.abs(rs - s)
    local tdelta = math.abs(rt - t)
    local zdelta = math.abs(rz - (-s - t))

    if sdelta > tdelta and sdelta > zdelta then
        rs = -rt - rz
    elseif tdelta > zdelta then
        rt = -rs - rz
    else
        rz = -rs - rt
    end
    return vec2(rs, rt)
end

----- [[ LAYOUT, ORIENTATION & COORDINATE CONVERSION  ]] -----------------------

-- forward & inverse matrices used for the flat orientation.
local FLAT = {M = mat2(3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5    ), 
              W = mat2(2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0)}

-- forward & inverse matrices used for the pointy orientation. 
local POINTY = {M = mat2(3.0^0.5,   3.0^0.5/2.0,  0.0,  3.0/2.0),  
                W = mat2(3.0^0.5/3.0,  -1.0/3.0,  0.0,  2.0/3.0)}

-- stores layout information that does not pertain to map shape. 
function hex_layout(origin, size, orientation)
    return {origin      = origin      or vec2(0),
            size        = size        or vec2(11),
            orientation = orientation or FLAT}
end    

-- hex to screen
function hex_to_pixel(hex, layout)
    local M = layout.orientation.M

    local x = (M[1][1] * hex.s + M[1][2] * hex.t) * layout.size.x
    local y = (M[2][1] * hex.s + M[2][2] * hex.t) * layout.size.y

    return vec2(x + layout.origin.x, y + layout.origin.y)
end

-- screen to hex
function pixel_to_hex(pix, layout)
    local W = layout.orientation.W

    local pix = (pix - layout.origin) / layout.size 

    local s = W[1][1] * pix.x + W[1][2] * pix.y
    local t = W[2][1] * pix.x + W[2][2] * pix.y

    return hex_round(s, t) 
end

----- [[ MAPS ]] --------------------------------------------------------------
--[[ Maps are tables of hex coordinates. They can be ordered or unordered.

  ]]

-- TODO make all functions work regardless of orientation.

-- returns an ordered map in a ring offset by |radius| from |center|.
function hex_ring_map(center, radius)
    local map = {}
    local walk = center + HEX_DIRECTIONS[5] * radius

    for i = 1, 6 do
        for j = 1, radius do
            table.insert(map, walk)
            walk = hex_neighbour(walk, i)
        end
    end
    return map
end

-- returns an ordered map in |radius| rings from |center|.
function hex_spiral_map(center, radius)
    local map = {center}

    for i = 1, radius do
        table.append(map, hex_ring(center, i, HEX_DIRECTIONS[5]))
    end
    return map
end

-- returns an unordered parallelogram-shaped map of |width| and |height|. 
function hex_parallelogram_map(width, height)
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

-- returns an unordered triangular map of |size|. 
function hex_triangular_map(size)
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

-- returns an unordered hexagonal map of |radius|.
function hex_hexagonal_map(radius) 
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

-- returns an unordered rectangular map of |width| and |height|.
function hex_rectangular_map(width, height)
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

