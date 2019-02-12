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
    +support for simple irregular hexagons (horizontal and vertical stretching).

    classes are used sparsely. maps implement a few constructors, for storing
    your maps elsewhere. 

        -- RESOURCES USED TO DEVELOP THIS LIBRARY
    https://redblobgames.com/grid/hexagons    - simply amazing. 
    http://amulet.xyz/doc                     - amulet documentation
    TODO that place that had the inner circle/outer circle ratio?? 

  ]]

----- [[ GENERALLY USEFUL FUNCTIONS ]] -----------------------------------------

-- just incase you don't already have a rounding function.  
local function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

---- [[ HEX CONSTANTS ]] -------------------------------------------------------

-- all possible vector directions from a given hex by edge
local HEX_DIRECTIONS = {vec2( 1 ,  0), 
                        vec2( 1 , -1), 
                        vec2( 0 , -1),
                        vec2(-1 ,  0), 
                        vec2(-1 ,  1), 
                        vec2( 0 ,  1)}

-- HEX UTILITY FUNCTIONS -------------------------------------------------------

function hex_equals(a, b)
    return a.s == b.s and a.t == b.t
end



local function hex_round(s, t)
    rs = round(s)
    rt = round(t)
    rz = round(-s - t)

    sdelta = math.abs(rs - s)
    tdelta = math.abs(rt - t)
    zdelta = math.abs(rz - (-s - t))

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

-- layout. 
function layout_init(origin, size, orientation)
    return {origin      = origin or vec2(0),
            size        = size or vec2(11),
            orientation = orientation or FLAT}
end    

-- hex to screen
function hex_to_pixel(hex, layout)
    M = layout.orientation
    
    x = (M[1] * hex.s + M[2] * hex.t) * layout.size.x
    y = (M[3] * hex.s + M[4] * hex.t) * layout.size.y

    return vec2(x + layout.origin.x, y + layout.origin.y)
end

-- screen to hex
function pixel_to_hex(pix, layout)
    M = layout.orientation

    pix = (pix - layout.origin) / layout.size 

    s = M[5] * pix.x + M[6] * pix.y
    t = M[7] * pix.x + M[8] * pix.y

    return hex_round(s, t) 
end

----- [[ MAP STORAGE & RETRIEVAL ]] --------------------------------------------

--[[ _init functions return a table of tables;
     a map of points in a chosen shape and specified layout.
     the shape, as well as the layout used is stored in a metatable
     for reuse.
  ]]

-- returns parallelogram-shaped map. 
function grammap_init(layout, width, height)
    map = {}
    setmetatable(map, {__index={layout=layout, 
                                width=width, 
                                height=height,
                                shape="parallelogram"}})
    for s = 0, width do
        for t = 0, height do
            table.insert(map, hex_to_pixel(vec2(s, t), layout)) 
        end
    end
    return map
end

-- returns triangular map. 
function trimap_init(layout, size)
    map = {}
    setmetatable(map, {__index={layout=layout, 
                                size=size,
                                shape="triangular"}})
    for s = 0, size do
        for t = size - s, size do
            table.insert(map, hex_to_pixel(vec2(s, t), layout))
        end
    end
    return map
end

-- returns hexagonal map. length of map is radius * 2 + 1 
function hexmap_init(layout, radius) 
    map = {}
    setmetatable(map, {__index={layout=layout, 
                                radius=radius,
                                shape="hexagonal"}})
    for s = -radius, radius do
        t1 = math.max(-radius, -s - radius)
        t2 = math.min(radius, -s + radius)

        for t = t1, t2 do
            table.insert(map, hex_to_pixel(vec2(s, t), layout))
        end
    end
    return map
end

-- returns rectangular map. 
function rectmap_init(layout, width, height)
    map = {}
    mt = {__index={layout=layout, width=width, height=height,
               
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

