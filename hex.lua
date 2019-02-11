--[[ AXIAL/CUBE COORDINATE SYSTEM FOR AMULET/LUA]]
--[[

    all hexes in functions are assumed to be amulet vectors. 
    in amulet, vector arithmetic works already with [ + - * / ]
    things like equality and distance are implemented here.

    some algorithms use axial coordinates for hexes: vec2(s, t)
    others use cube coordinates: vec3(s, t, z) where s + t + z = 0
    this is for simplicity - many algorithms don't care about the
    third coordinate, and if they do, the missing coordinate can 
    be calculated from the other two.

        -- note on orientation:
    because of the way amulet draws hexagons, it's much easier to assume
    the user wants to use the flat map. rotation after the fact to
    achieve other orienations is probably possible, but might have some
    aliasing issues. TODO work on this.

    some of the primary resources used to develop this library:
    - https://redblobgames.com/grid/hexagons    - simply amazing. 
    - http://amulet.xyz/doc                     - amulet documentation
    - TODO that place that had the inner circle/outer circle ratio?? 
  
  ]]


-- GENERALLY USEFUL FUNCTIONS --------------------------------------------------

function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end


-- HEX CONSTANTS ---------------------------------------------------------------

    -- all possible vector directions from a given hex by edge
HEX_DIRECTIONS = {vec2( 1 ,  0), 
                  vec2( 1 , -1), 
                  vec2( 0 , -1),
                  vec2(-1 ,  0), 
                  vec2(-1 ,  1), 
                  vec2( 0 ,  1)}

-- HEX UTILITY FUNCTIONS -------------------------------------------------------

function hex_equals(a, b)
    return a.s == a.t and b.s == b.t
end

function hex_nequals(a, b)
    return not hex_equals(a, b)
end

function hex_length(hex)
    return ((math.abs(hex.s) + math.abs(hex.t) + math.abs(-hex.s - hex.t)) / 2)
end

function hex_distance(a, b)
    return hex_length(a - b)
end

function hex_direction(direction)
    return HEX_DIRECTIONS[direction]
end

function hex_neighbour(hex, direction)
    return hex + HEX_DIRECTIONS[direction] 
end

function hex_round(hex)
    rs = round(hex.s)
    rt = round(hex.t)
    rz = round(-hex.s + -hex.t)

    sdelta = math.abs(rs - hex.s)
    tdelta = math.abs(rt - hex.t)
    zdelta = math.abs(rz + hex.s + hex.t)

    if sdelta > tdelta and sdelta > zdelta then
        rs = -rt - rz
    elseif tdelta > zdelta then
        rt = -rs - rz
    else
        rz = -rs - rt
    end

    return vec2(rs, rt)
end

-- COORDINATE CONVERSION FUNCTIONS ---------------------------------------------

    -- forward & inverse matrices used for coordinate conversion
local M = mat2(3.0/2.0,     0.0,    3.0^0.5/2.0,    3.0^0.5    )
local W = mat2(2.0/3.0,     0.0,    -1.0/3.0   ,    3.0^0.5/3.0)

    -- hex to screen
function hex_to_pixel(hex)

    x = (M[1][1] * hex.s + M[1][2] * hex.t) * map.size
    y = (M[2][1] * hex.s + M[2][2] * hex.t) * map.size

    return vec2(x + map.origin.x, y + map.origin.y)
end

    -- screen to hex
function pixel_to_hex(pix)
    pix = vec2(pix.x - map.origin.x) / map.size, 
              (pix.y - map.origin.y) / map.size

    s = W[1][1] * pix.x + W[1][2] * pix.y
    t = W[2][1] * pix.x + W[2][2] * pix.y

    return hex_round(vec2(s, t)) 
end

-- MAP FUNCTIONS ---------------------------------------------------------------
