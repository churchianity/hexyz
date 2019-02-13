----- [[ AXIAL/CUBE COORDINATE SYSTEM FOR AMULET/LUA]] -------------------------
--[[                                                     author@churchianity.ca
        -- INTRODUCTION
    this is a hexagonal grid library for amulet/lua.
    it uses axial coordinates or cube/hex coordinates when necessary.
    by amulet convention, hexes are either vec2(s, t) or vec3(s, t, z)
    but nearly always the former. 
    
    in some rare cases, coordinates will be passed individually, usually
    because they are only passed internally and should never be adjusted
    directly.

    in amulet, vector arithmetic already works via: + - * / 
    additional things such as equality, and distance are implemented here.
    
    +support for parallelogram, triangular, hexagonal and rectangular maps.
    +support for arbitrary maps with gaps via hashmaps-like storage
    +support for simple irregular hexagons (horizontal and vertical stretching).

    classes are used sparsely. maps implement a few constructors for storing
    your maps elsewhere, and should be the only field that is necessarily 
    visible outside the library.

        -- RESOURCES USED TO DEVELOP THIS LIBRARY
    https://redblobgames.com/grid/hexagons    - simply amazing. 
    http://amulet.xyz/doc                     - amulet documentation
    TODO that place that had the inner circle/outer circle ratio?? 

  ]]

----- [[ GENERALLY USEFUL FUNCTIONS ]] -----------------------------------------

-- rounds numbers. would've been cool to have math.round in lua.  
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

----- [[ HEX CONSTANTS ]] ------------------------------------------------------

-- all possible vector directions from a given hex by edge
local HEX_DIRECTIONS = {vec2( 1 ,  0), 
                        vec2( 1 , -1), 
                        vec2( 0 , -1),
                        vec2(-1 ,  0), 
                        vec2(-1 ,  1), 
                        vec2( 0 ,  1)}

----- [[ HEX UTILITY FUNCTIONS ]] ----------------------------------------------

function hex_equals(a, b)
    return a.s == b.s and a.t == b.t
end

function hex_length(hex)
    return round(math.abs(hex.s) + math.abs(hex.r) + math.abs(-hex.s - hex.t)/2)
end

function hex_distance(a, b)
    return hex_length(a - b)
end

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
local FLAT = {3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5, 
              2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0}

-- forward & inverse matrices used for the pointy orientation. 
local POINTY = {3.0^0.5,  3.0^0.5/2.0,  0.0,  3.0/2.0,  
                3.0^0.5/3.0,  -1.0/3.0,  0.0,  2.0/3.0}

-- stores layout information that does not pertain to map shape 
function layout_init(origin, size, orientation)
    return {origin      = origin      or vec2(0),
            size        = size        or vec2(11),
            orientation = orientation or FLAT}
end    

-- hex to screen
function hex_to_pixel(hex, layout)
    local M = layout.orientation
    
    local x = (M[1] * hex.s + M[2] * hex.t) * layout.size.x
    local y = (M[3] * hex.s + M[4] * hex.t) * layout.size.y

    return vec2(x + layout.origin.x, y + layout.origin.y)
end

-- screen to hex
function pixel_to_hex(pix, layout)
    local M = layout.orientation

    local pix = (pix - layout.origin) / layout.size 

    local s = M[5] * pix.x + M[6] * pix.y
    local t = M[7] * pix.x + M[8] * pix.y

    return hex_round(s, t) 
end

----- [[ MAP STORAGE & RETRIEVAL ]] --------------------------------------------

--[[ _init functions return a table of tables;
     a map of points in a chosen shape and specified layout.
     
     grammap_init       -       parallelogram map
     trimap_init        -       triangular map
     hexmap_init        -       hexagonal map
     rectmap_init       -       rectangular map

     calling .retrieve(pix) on your map will get the hexagon at that pixel.
     calling .store(hex) on your map will store that hex as pixel coords.
     
     maps store coordinates like this:

     map[hex] = hex_to_pixel(hex)

     this means you should be able to get all the information you need about
     various coordinates completely within the map 'class', without calling
     any internal functions. indeed, *map_init, map.retrieve, and map.store
     is all you need.
  ]]

-- returns parallelogram-shaped map. 
function grammap_init(layout, width, height)
    local map = {}
    local mt = {__index={layout=layout, 

            -- get hex in map from pixel coordinate
            retrieve=function(pix)
                return pixel_to_hex(pix, layout)
            end,

            -- store pixel in map from hex coordinate
            store=function(hex)
                map[hex]=hex_to_pixel(hex, layout)             
            end
            }}
    
    setmetatable(map, mt)
    
    for s = 0, width do
        for t = 0, height do
            table.insert(map, hex_to_pixel(vec2(s, t), layout)) 
        end
    end
    return map
end

-- returns triangular map. 
function trimap_init(layout, size)
    local map = {}
    local mt = {__index={layout=layout,
    
            -- get hex in map from pixel coordinate
            retrieve=function(pix)
                return pixel_to_hex(pix, layout)
            end,

            -- store pixel in map from hex coordinate
            store=function(hex)
                map[hex]=hex_to_pixel(hex, layout)
            end
            }}
    
    setmetatable(map, mt)

    for s = 0, size do
        for t = size - s, size do
            map.store(vec2(s, t))
        end
    end
    return map
end

-- returns hexagonal map. length of map is radius * 2 + 1 
function hexmap_init(layout, radius) 
    local map = {}
    local mt = {__index={layout=layout,
            
            -- get hex in map from pixel coordinate
            retrieve=function(pix)
                return pixel_to_hex(pix, layout)
            end,

            -- store pixel in map from hex coordinate
            store=function(hex)
                map[hex]=hex_to_pixel(hex, layout)        
            end
            }}

    setmetatable(map, mt)

    for s = -radius, radius do
        local t1 = math.max(-radius, -s - radius)
        local t2 = math.min(radius, -s + radius)

        for t = t1, t2 do
            table.insert(map, hex_to_pixel(vec2(s, t), layout))
        end
    end
    return map
end

-- returns rectangular map. 
function rectmap_init(layout, width, height)
    local map = {}
    local mt = {__index={layout=layout,
               
            -- get hex in map from pixel coordinate                    
            retrieve=function(pix)
                return pixel_to_hex(pix, layout)
            end,

            -- store pixel in map from hex coordinate
            store=function(hex)
                map[hex]=hex_to_pixel(hex - vec2(0, math.floor(hex.s/2)), layout) 
            end
            }}
    
    setmetatable(map, mt) 
        
    for s = 0, width do
        for t = 0, height do
            map.store(vec2(s, t))
        end
    end
    return map 
end

