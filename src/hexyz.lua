

-- this is a single file with no dependencies which is meant to perform a bunch of mathy stuff
-- related to hexagons, grids of them, and pathfinding on them
--
-- it basically owes its entire existence to this resource: https://www.redblobgames.com/grids/hexagons/
-- it uses some datatypes internal to the amulet game engine: http://www.amulet.xyz/
-- (vec2, mat2)
-- and some utility functions not present in your standard lua, like:
--  table.append


if not math.round then
    math.round = function(n) return math.floor(n + 0.5) end
else
    error("clobbering 'math.round', oopsie!")
end

-- @TODO
if not table.append then end
if not table.filter then end

-- wherever 'orientation' appears as an argument, use one of these two, or set a default just below
HEX_ORIENTATION = {
    -- Forward & Inverse Matrices used for the Flat Orientation
    FLAT = {
        M = mat2(3.0/2.0, 0.0, 3.0^0.5/2.0, 3.0^0.5    ),
        W = mat2(2.0/3.0, 0.0, -1.0/3.0   , 3.0^0.5/3.0),
        angle = 0.0
    },
    -- Forward & Inverse Matrices used for the Pointy Orientation
    POINTY = {
        M = mat2(3.0^0.5,     3.0^0.5/2.0, 0.0, 3.0/2.0),
        W = mat2(3.0^0.5/3.0,    -1.0/3.0, 0.0, 2.0/3.0),
        angle = 0.5
    }
}

-- whenever |orientation| appears as an argument, if it isn't provided, this is used instead.
-- this is useful because most of the time you will only care about one orientation
local HEX_DEFAULT_ORIENTATION = HEX_ORIENTATION.FLAT

-- whenever |size| for a hexagon appears as an argument, if it isn't provided, use this
-- 'size' here is distance from the centerpoint to any vertex in pixel
local HEX_DEFAULT_SIZE = vec2(26)

-- actual width (longest contained horizontal line) of the hexagon
function hex_width(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION

    if orientation == HEX_ORIENTATION.FLAT then
        return size * 2

    elseif orientation == HEX_ORIENTATION.POINTY then
        return math.sqrt(3) * size
    end
end

-- actual height (tallest contained vertical line) of the hexagon
function hex_height(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION

    if orientation == HEX_ORIENTATION.FLAT then
        return math.sqrt(3) * size

    elseif orientation == HEX_ORIENTATION.POINTY then
        return size * 2
    end
end

-- returns actual width and height of a hexagon given it's |size| which is the distance from the centerpoint to any vertex in pixels
function hex_dimensions(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION
    return vec2(hex_width(size, orientation), hex_height(size, orientation))
end

-- distance between two horizontally adjacent hexagon centerpoints
function hex_horizontal_spacing(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION

    if orientation == HEX_ORIENTATION.FLAT then
        return hex_width(size, orientation) * 3/4

    elseif orientation == HEX_ORIENTATION.POINTY then
        return hex_height(size, orientation)
    end
end

-- distance between two vertically adjacent hexagon centerpoints
function hex_vertical_spacing(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION

    if orientation == HEX_ORIENTATION.FLAT then
        return hex_height(size, orientation)

    elseif orientation == HEX_ORIENTATION.POINTY then
        return hex_width(size, orientation) * 3/4
    end
end

-- returns the distance between adjacent hexagon centers in a grid
function hex_spacing(size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION
    return vec2(hex_horizontal_spacing(size, orientation), hex_vertical_spacing(size, orientation))
end

-- All Non-Diagonal Vector Directions from a Given Hex by Edge
HEX_DIRECTIONS = { vec2( 1 , -1), vec2( 1 ,  0), vec2(0 ,  1),
                   vec2(-1 ,  1), vec2(-1 ,  0), vec2(0 , -1) }

-- Return Hex Vector Direction via Integer Index |direction|
function hex_direction(direction)
    return HEX_DIRECTIONS[(direction % 6) % 6 + 1]
end

-- Return Hexagon Adjacent to |hex| in Integer Index |direction|
function hex_neighbour(hex, direction)
    return hex + HEX_DIRECTIONS[(direction % 6) % 6 + 1]
end

-- Collect All 6 Neighbours in a Table
function hex_neighbours(hex)
    local neighbours = {}
    for i = 1, 6 do
        table.insert(neighbours, hex_neighbour(hex, i))
    end
    return neighbours
end

-- Returns a vec2 Which is the Nearest |x, y| to Float Trio |x, y, z|
-- assumes you have a working math.round function (should be guarded at top of this file)
local function hex_round(x, y, z)
    local rx = math.round(x)
    local ry = math.round(y)
    local rz = math.round(z) or math.round(-x - y)

    local xdelta = math.abs(rx - x)
    local ydelta = math.abs(ry - y)
    local zdelta = math.abs(rz - z or math.round(-x - y))

    if xdelta > ydelta and xdelta > zdelta then
        rx = -ry - rz
    elseif ydelta > zdelta then
        ry = -rx - rz
    else
        rz = -rx - ry
    end

    return vec2(rx, ry)
end

-- Hex to Screen -- Orientation Must be Either POINTY or FLAT
function hex_to_pixel(hex, size, orientation)
    local M = orientation and orientation.M or HEX_DEFAULT_ORIENTATION.M

    local x = (M[1][1] * hex[1] + M[1][2] * hex[2]) * (size and size[1] or HEX_DEFAULT_SIZE[1])
    local y = (M[2][1] * hex[1] + M[2][2] * hex[2]) * (size and size[2] or HEX_DEFAULT_SIZE[2])

    return vec2(x, y)
end

-- Screen to Hex -- Orientation Must be Either POINTY or FLAT
function pixel_to_hex(pix, size, orientation)
    local W = orientation and orientation.W or HEX_DEFAULT_ORIENTATION.W

    local pix = pix / (size or vec2(HEX_DEFAULT_SIZE))

    local x = W[1][1] * pix[1] + W[1][2] * pix[2]
    local y = W[2][1] * pix[1] + W[2][2] * pix[2]

    return hex_round(x, y, -x - y)
end

-- TODO test, learn am.draw
function hex_corner_offset(corner, size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION
    local angle = 2.0 * math.pi * orientation.angle + corner / 6
    return vec2(size[1] * math.cos(angle), size[2] * math.sin(angle))
end

-- TODO test this thing
function hex_corners(hex, size, orientation)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION
    local corners = {}
    local center = hex_to_pixel(hex, size, orientation)
    for i = 0, 5 do
        local offset = hex_corner_offset(i, size, orientation)
        table.insert(corners, center + offset)
    end
    return corners
end

-- @TODO test
function hex_to_oddr(hex)
    local z = -hex.x - hex.y
    return vec2(hex.x + (z - (z % 2)) / 2)
end

-- @TODO test
function oddr_to_hex(oddr)
    return vec2(hex.x - (hex.y - (hex.y % 2)) / 2, -hex.x - hex.y)
end

-- @TODO test
function hex_to_evenr(hex)
    local z = -hex.x - hex.y
    return vec2(hex.x + (z + (z % 2)) / 2, z)
end

-- @TODO test
function evenr_to_hex(evenr)
    return vec2(hex.x - (hex.y + (hex.y % 2)) / 2, -hex.x - hex.y)
end

-- @TODO test
function hex_to_oddq(hex)
    return vec2(hex.x, -hex.x - hex.y + (hex.x - (hex.x % 2)) / 2)
end

-- @TODO test
function oddq_to_hex(oddq)
    return vec2(hex.x, -hex.x - (hex.y - (hex.x - (hex.y % 2)) / 2))
end

function hex_to_evenq(hex)
    return vec2(hex.x, (-hex.x - hex.y) + (hex.x + (hex.x % 2)) / 2)
end

function evenq_to_hex(evenq)
    return vec2(evenq.x, -evenq.x - (evenq.y - (evenq.x + (evenq.x % 2)) / 2))
end

--============================================================================
-- MAPS & STORAGE

-- maps that use their indices as the hex coordinates (parallelogram, hexagonal, rectangular, triangular),
-- fail to serialize ideally because they use negative indices, which json doesn't support


-- Returns Ordered Ring-Shaped Map of |radius| from |center|
function hex_ring_map(center, radius)
    local map = {}

    local walk = center + HEX_DIRECTIONS[6] * radius

    for i = 1, 6 do
        for j = 1, radius do
            table.insert(map, walk)
            walk = hex_neighbour(walk, i)
        end
    end
    return setmetatable(map, {__index={center=center, radius=radius}})
end

-- Returns Ordered Spiral Hexagonal Map of |radius| Rings from |center|
function hex_spiral_map(center, radius)
    local map = { center }

    for i = 1, radius do
        table.append(map, hex_ring_map(center, i))
    end
    return setmetatable(map, {__index={center=center, radius=radius}})
end

function hex_map_get(map, hex, y)
    if y then return map[hex] and map[hex][y] end
    return map[hex.x] and map[hex.x][hex.y]
end

function hex_map_set(map, hex, y, v)
    if v then
        if map[hex] then
            map[hex][y] = v
        else
            map[hex] = {}
            map[hex][y] = v
        end
    else
        if map[hex.x] then
            map[hex.x][hex.y] = y
        else
            map[hex.x] = {}
            map[hex.x][hex.y] = y
        end
    end
end

-- Returns Unordered Parallelogram-Shaped Map of |width| and |height| with Simplex Noise
function hex_parallelogram_map(width, height, seed)
    local seed = seed or math.random(width * height)

    local map = {}
    for i = 0, width - 1 do
        map[i] = {}
        for j = 0, height - 1 do

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
    return setmetatable(map, { __index = {
        width = width,
        height = height,
        seed = seed,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return hex_map_get(map, _hex)
            end)
        end
    }})
end

-- Returns Unordered Triangular (Equilateral) Map of |size| with Simplex Noise
function hex_triangular_map(size, seed)
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
    return setmetatable(map, { __index = {
        size = size,
        seed = seed,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return hex_map_get(map, _hex)
            end)
        end
    }})
end

-- Returns Unordered Hexagonal Map of |radius| with Simplex Noise
function hex_hexagonal_map(radius, seed)
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
    return setmetatable(map, { __index = {
        radius = radius,
        seed = seed,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return hex_map_get(map, _hex.x, _hex.y)
            end)
        end
    }})
end

-- Returns Unordered Rectangular Map of |width| and |height| with Simplex Noise
function hex_rectangular_map(width, height, orientation, seed)
    local orientation = orientation or HEX_DEFAULT_ORIENTATION
    local seed = seed or math.random(width * height)

    local map = {}
    if orientation == HEX_ORIENTATION.FLAT then
        for i = 0, width - 1 do
            map[i] = {}
            for j = 0, height - 1 do

                -- begin to calculate noise
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

                map[i][j] = noise
            end
        end
    elseif orientation == HEX_ORIENTATION.POINTY then
        for i = 0, height - 1 do
            local i_offset = math.floor(i/2)
            for j = -i_offset, width - i_offset - 1 do
                hex_map_set(map, j, i, 0)
            end
        end
    else
        error("bad orientation value")
    end

    return setmetatable(map, { __index = {
        width = width,
        height = height,
        seed = seed,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return hex_map_get(map, _hex)
            end)
        end
    }})
end

--============================================================================
-- PATHFINDING
-- note:
--  i kinda feel like after implementing these and making the game, there are tons of reasons
--  why you might want to specialize pathfinding, like you would any other kind of algorithm
--
--  so, while (in theory) these algorithms work with the maps in this file, your maps and game
--  will have lots of other data which you may want your pathfinding algorithms to care about in some way,
--  that these don't.
--
function hex_breadth_first(map, start, neighbour_f)
    local frontier = {}
    frontier[1] = start

    local distance = {}
    hex_map_set(distance, start, 0)

    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        for _,neighbour in pairs(neighbour_f(map, current)) do
            local d = hex_map_get(distance, neighbour)
            if not d then
                table.insert(frontier, neighbour)
                local current_distance = hex_map_get(distance, current)
                hex_map_set(distance, neighbour, current_distance + 1)
            end
        end
    end

    return distance
end

function hex_dijkstra(map, start, goal, neighbour_f, cost_f)
    local frontier = {}
    frontier[1] = { hex = start, priority = 0 }

    local came_from = {}
    hex_map_set(came_from, start, false)

    local cost_so_far = {}
    hex_map_set(cost_so_far, start, 0)

    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        if goal and current.hex == goal then
            break
        end

        for _,neighbour in pairs(neighbour_f(map, current.hex)) do
            local new_cost = hex_map_get(cost_so_far, current.hex) + cost_f(map, current.hex, neighbour)
            local neighbour_cost = hex_map_get(cost_so_far, neighbour)

            if not neighbour_cost or (new_cost < neighbour_cost) then
                hex_map_set(cost_so_far, neighbour, new_cost)
                local priority = new_cost + math.distance(start, neighbour)
                table.insert(frontier, { hex = neighbour, priority = priority })
                hex_map_set(came_from, neighbour, current)
            end
        end
    end

    return came_from
end

-- A* pathfinding
--
--  |heuristic| has the form:
--  function(source, target)     -- source and target are vec2's
--      return some numeric value
--
--  |cost_f| has the form:
--  function (from, to)         -- from and to are vec2's
--      return some numeric value
--
function hex_Astar(map, start, goal, neighbour_f, cost_f, heuristic)
    local path = {}
    hex_map_set(path, start, false)

    local frontier = {}
    frontier[1] = { hex = start, priority = 0 }

    local path_so_far = {}
    hex_map_set(path_so_far, start, 0)

    local made_it = false
    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        if current.hex == goal then
            made_it = true
            break
        end

        for _,next_ in pairs(neighbour_f(map, current.hex)) do
            local new_cost = hex_map_get(path_so_far, current.hex) + cost_f(map, current.hex, next_)
            local next_cost = hex_map_get(path_so_far, next_)

            if not next_cost or new_cost < next_cost then
                hex_map_set(path_so_far, next_, new_cost)
                local priority = new_cost + heuristic(goal, next_)
                table.insert(frontier, { hex = next_, priority = priority })
                hex_map_set(path, next_, current)
            end
        end
    end

    return path, made_it
end

