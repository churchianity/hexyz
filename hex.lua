----- [[ AXIAL/CUBE COORDINATE SYSTEM FOR AMULET/LUA]] -------------------------
--[[                                                     author@churchianity.ca
        -- INTRODUCTION
    this is a library for making grids of hexagons using lua.
    it has made use of exclusively standard lua 5.2 functionality,
    making it as portable as possible. it doesn't even use a point 
    class, (or classes/metatables at all) simply returning tables 
    of integers, which can later be unpacked into your amulet 
    vectors, or whatever else you want to use. 

    this can result in some nasty looking lines with lots of table 
    unpacks, but if your graphics library likes traditional lua
    types, you will be better off. 

    it supports triangular, hexagonal, rectangular, and 
    parallelogram map shapes. 
    
    it supports non-regular hexagons, though it's trickier to get
    working in amulet. TODO work on this.

        -- NOTE ON ORIENTATION + AMULET
    because of the way amulet draws hexagons (amulet essentially
    draws a 6-sided circle from a centerpoint, instead of of a 
    series of lines connecting points), the flat orientation is 
    default and recommended. other orientations are possible 
    with am.rotate, but can cause aliasing issues. TODO work on this.

        -- RESOURCES USED TO DEVELOP THIS LIBRARY
    https://redblobgames.com/grid/hexagons    - simply amazing. amit is a god. 
    http://amulet.xyz/doc                     - amulet documentation
    TODO that place that had the inner circle/outer circle ratio?? 

  ]]

----- [[ GENERALLY USEFUL FUNCTIONS ]] -----------------------------------------

-- just incase you don't already have a rounding function.  
function round(n)
    return n % 1 >= 0.5 and math.ceil(n) or math.floor(n)
end

---- [[ HEX CONSTANTS ]] -------------------------------------------------------

-- all possible vector directions from a given hex by edge
HEX_DIRECTIONS = {{ 1 ,  0}, 
                  { 1 , -1}, 
                  { 0 , -1},
                  {-1 ,  0}, 
                  {-1 ,  1}, 
                  { 0 ,  1}}

-- HEX UTILITY FUNCTIONS -------------------------------------------------------

function hex_round(s, t)
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

    return {rs, rt}
end

----- [[ LAYOUT, ORIENTATION & COORDINATE CONVERSION  ]] -----------------------

-- forward & inverse matrices used for the flat orientation.
FLAT_ORIENTATION = {3.0/2.0,  0.0,  3.0^0.5/2.0,  3.0^0.5, 
                    2.0/3.0,  0.0,  -1.0/3.0   ,  3.0^0.5/3.0}

-- forward & inverse matrices used for the pointy orientation. 
POINTY_ORIENTATION = {3.0^0.5,  3.0^0.5/2.0,  0.0,  3.0/2.0,  
                      3.0^0.5/3.0,  -1.0/3.0,  0.0,  2.0/3.0}

-- layout. 
function layout_init(origin, size, orientation)
    return {origin      = origin or {0, 0},
            size        = size or {11, 11},
            orientation = orientation or FLAT_ORIENTATION}
end    

-- hex to screen
function hex_to_pixel(s, t, layout)
    M = layout.orientation
    
    x = (M[1] * s + M[2] * t) * layout.size[1]
    y = (M[3] * s + M[4] * t) * layout.size[2]

    return {x + layout.origin[1], y + layout.origin[2]}
end

-- screen to hex
function pixel_to_hex(x, y, layout)
    M = layout.orientation

    px = {(x - layout.origin[1]) / layout.size[1], 
          (y - layout.origin[2]) / layout.size[2]}

    s = M[5] * px[1] + M[6] * px[2]
    t = M[7] * px[1] + M[8] * px[2]

    return hex_round(s, t) 
end

----- [[ MAP STORAGE & RETRIEVAL ]] --------------------------------------------

--[[ _init functions return a table of tables;
     a map of points in a chosen shape and specified layout.
     the shape, as well as the layout used is stored in a metatable
     for reuse.
  ]]

-- returns parallelogram-shaped map. 
function map_parallelogram_init(layout, width, height)
    map = {}
    setmetatable(map, {__index={layout=layout, shape=parallelogram}})

    for s = 0, width do
        for t = 0, height do
            table.insert(map, hex_to_pixel(s, t, layout)) 
        end
    end
    return map
end

-- returns triangular map. 
function map_triangular_init(layout, size)
    map = {}
    setmetatable(map, {__index={layout=layout, shape=triangular}})
    
    for s = 0, size do
        for t = size - s, size do
            table.insert(map, hex_to_pixel(s, t, layout))
        end
    end
    return map
end

-- returns hexagonal map. length of map is radius * 2 + 1 
function map_hexagonal_init(layout, radius) 
    map = {}
    setmetatable(map, {__index={layout=layout, shape=hexagonal}})
    
    for s = -radius, radius do
        t1 = math.max(-radius, -s - radius)
        t2 = math.min(radius, -s + radius)

        for t = t1, t2 do
            table.insert(map, hex_to_pixel(s, t, layout))
        end
    end
    return map
end

-- returns rectangular map. 
function map_rectangular_init(layout, width, height)
    map = {}
    setmetatable(map, {__index={layout=layout, shape=rectangular}})
    
    for s = 0, width do
        soffset = math.floor(s/2)

        for t = -soffset, height - soffset do
            table.insert(map, hex_to_pixel(s, t, layout))
        end
    end
    return map
end

-- places single hex into map table, if it is not already present.
function map_store(map)

end

-- retrieves single hex from map table, if it is present.
function map_retrieve(map)

end

