

if not math.round then
    math.round = function(n) return math.floor(n + 0.5) end
else
    log("clobbering a math.round function.")
end


-- wherever 'orientation' appears as an argument, use one of these two, or set a default just below
ORIENTATION = {
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

-- whenver |orientation| appears as an argument, if it isn't provided, this is used instead.
local DEFAULT_ORIENTATION = ORIENTATION.FLAT

-- whenever |size| for a hexagon appears as an argument, if it isn't provided, use this
-- 'size' here is distance from the centerpoint to any vertex in pixel
local DEFAULT_HEX_SIZE = vec2(20)

-- actual width (longest contained horizontal line) of the hexagon
function hex_width(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION

    if orientation == ORIENTATION.FLAT then
        return size * 2

    elseif orientation == ORIENTATION.POINTY then
        return math.sqrt(3) * size
    end
end

-- actual height (tallest contained vertical line) of the hexagon
function hex_height(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION

    if orientation == ORIENTATION.FLAT then
        return math.sqrt(3) * size

    elseif orientation == ORIENTATION.POINTY then
        return size * 2
    end
end

-- returns actual width and height of a hexagon given it's |size| which is the distance from the centerpoint to any vertex in pixels
function hex_dimensions(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION
    return vec2(hex_width(size, orientation), hex_height(size, orientation))
end

-- distance between two horizontally adjacent hexagon centerpoints
function hex_horizontal_spacing(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION

    if orientation == ORIENTATION.FLAT then
        return hex_width(size, orientation) * 3/4

    elseif orientation == ORIENTATION.POINTY then
        return hex_height(size, orientation)
    end
end

-- distance between two vertically adjacent hexagon centerpoints
function hex_vertical_spacing(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION

    if orientation == ORIENTATION.FLAT then
        return hex_height(size, orientation)

    elseif orientation == ORIENTATION.POINTY then
        return hex_width(size, orientation) * 3/4
    end
end

-- returns the distance between adjacent hexagon centers in a grid
function hex_spacing(size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION
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
    local M = orientation and orientation.M or DEFAULT_ORIENTATION.M

    local x = (M[1][1] * hex[1] + M[1][2] * hex[2]) * (size and size[1] or DEFAULT_HEX_SIZE[1])
    local y = (M[2][1] * hex[1] + M[2][2] * hex[2]) * (size and size[2] or DEFAULT_HEX_SIZE[2])

    return vec2(x, y)
end

-- Screen to Hex -- Orientation Must be Either POINTY or FLAT
function pixel_to_hex(pix, size, orientation)
    local W = orientation and orientation.W or DEFAULT_ORIENTATION.W

    local pix = pix / (size or vec2(DEFAULT_HEX_SIZE))

    local x = W[1][1] * pix[1] + W[1][2] * pix[2]
    local y = W[2][1] * pix[1] + W[2][2] * pix[2]

    return hex_round(x, y, -x - y)
end

-- TODO test, learn am.draw
function hex_corner_offset(corner, size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION
    local angle = 2.0 * math.pi * orientation.angle + corner / 6
    return vec2(size[1] * math.cos(angle), size[2] * math.sin(angle))
end

-- TODO test this thing
function hex_corners(hex, size, orientation)
    local orientation = orientation or DEFAULT_ORIENTATION
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
    return setmetatable(map, {__index={center=center, radius=radius}})
end

-- Returns Ordered Spiral Hexagonal Map of |radius| Rings from |center|
function spiral_map(center, radius)
    local map = {center}

    for i = 1, radius do
        table.append(map, ring_map(center, i))
    end
    return setmetatable(map, {__index={center=center, radius=radius}})
end

local function map_get(t, x, y)
    return t[x] and t[x][y]
end
function hex_map_get(t, x, y)
    return map_get(t, x, y)
end

local function map_set(t, x, y, v)
    if t[x] then
        t[x][y] = v
    else
        t[x] = {}
        t[x][y] = v
    end

    return t
end
function hex_map_set(t, x, y, v)
    return map_set(t, x, y, v)
end

local function map_traverse(t, callback)
    for i,_ in pairs(t) do
        for _,entry in pairs(t[i]) do
            callback(entry)
        end
    end
end

-- @NOTE probably shouldn't use this...
local function map_partial_set(t, x, y, k, v)
    local entry = map_get(t, x, y)

    if not entry then
        map_set(t, x, y, { k = v })

    else
        entry.k = v
    end

    return t
end

-- Returns Unordered Parallelogram-Shaped Map of |width| and |height| with Simplex Noise
function parallelogram_map(width, height, seed)
    local seed = seed or math.random(width * height)

    local map = {}
    for i = 0, width do
        map[i] = {}
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
            map[i][j] = noise
        end
    end
    return setmetatable(map, { __index = {
        width = width,
        height = height,
        seed = seed,
        get = function(x, y) return map_get(map, x, y) end,
        set = function(x, y, v) return map_set(map, x, y, v) end,
        partial = function(x, y, k, v) return map_partial_set(map, x, y, k, v) end,
        traverse = function(callback) return map_traverse(map, callback) end,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return map.get(_hex.x, _hex.y)
            end)
        end
    }})
end

-- Returns Unordered Triangular (Equilateral) Map of |size| with Simplex Noise
function triangular_map(size, seed)
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
        get = function(x, y) return map_get(map, x, y) end,
        set = function(x, y, v) return map_set(map, x, y, v) end,
        partial = function(x, y, k, v) return map_partial_set(map, x, y, k, v) end,
        traverse = function(callback) return map_traverse(map, callback) end,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return map.get(_hex.x, _hex.y)
            end)
        end
    }})
end

-- Returns Unordered Hexagonal Map of |radius| with Simplex Noise
function hexagonal_map(radius, seed)
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
        get = function(x, y) return map_get(map, x, y) end,
        set = function(x, y, v) return map_set(map, x, y, v) end,
        partial = function(x, y, k, v) return map_partial_set(map, x, y, k, v) end,
        traverse = function(callback) return map_traverse(map, callback) end,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return map.get(_hex.x, _hex.y)
            end)
        end
    }})
end

-- Returns Unordered Rectangular Map of |width| and |height| with Simplex Noise
function rectangular_map(width, height, seed)
    local seed = seed or math.random(width * height)

    local map = {}
    for i = 0, width - 1 do
        map[i] = {}
        for j = 0, height - 1 do

            -- Begin to Calculate Noise
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
    return setmetatable(map, { __index = {
        width = width,
        height = height,
        seed = seed,
        get = function(x, y) return map_get(map, x, y) end,
        set = function(x, y, v) return map_set(map, x, y, v) end,
        partial = function(x, y, k, v) return map_partial_set(map, x, y, k, v) end,
        traverse = function(callback) return map_traverse(map, callback) end,
        neighbours = function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return map.get(_hex.x, _hex.y)
            end)
        end
    }})
end

--============================================================================
-- PATHFINDING


function breadth_first(map, start)
    local frontier = {}
    frontier[1] = start

    local distance = {}
    distance[start.x] = {}
    distance[start.x][start.y] = 0

    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        for _,neighbour in pairs(map.neighbours(current)) do
            local d = map_get(distance, neighbour.x, neighbour.y)
            if not d then
                table.insert(frontier, neighbour)
                local current_distance = map_get(distance, current.x, current.y)
                map_set(distance, neighbour.x, neighbour.y, current_distance + 1)
            end
        end
    end

    return distance
end

function dijkstra(map, start, goal, cost_f)
    local frontier = {}
    frontier[1] = { hex = start, priority = 0 }

    local came_from = {}
    came_from[start.x] = {}
    came_from[start.x][start.y] = false

    local cost_so_far = {}
    cost_so_far[start.x] = {}
    cost_so_far[start.x][start.y] = 0

    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        if goal and current.hex == goal then
            break
        end

        for _,neighbour in pairs(map.neighbours(current.hex)) do
            local new_cost = map_get(cost_so_far, current.hex.x, current.hex.y) + cost_f(map, current.hex, neighbour)
            local neighbour_cost = map_get(cost_so_far, neighbour.x, neighbour.y)

            if not neighbour_cost or (new_cost < neighbour_cost) then
                map_set(cost_so_far, neighbour.x, neighbour.y, new_cost)
                local priority = new_cost + math.distance(start, neighbour)
                table.insert(frontier, { hex = neighbour, priority = priority })
                map_set(came_from, neighbour.x, neighbour.y, current)
            end
        end
    end

    return came_from
end

-- generic A* pathfinding
--
--  |heuristic| has the form:
--  function(source, target)     -- source and target are vec2's
--      return some numeric value
--
--  |cost_f| has the form:
--  function (from, to)         -- from and to are vec2's
--      return some numeric value
--
-- returns a map that has map[hex.x][hex.y] = { hex = vec2, priority = number },
-- where the hex is the spot it thinks you should go to from the indexed hex, and priority is the cost of that decision,
-- as well as 'made_it' a bool that tells you if we were successful in reaching |goal|
function Astar(map, start, goal, heuristic, cost_f)
    local path = {}
    path[start.x] = {}
    path[start.x][start.y] = false

    local frontier = {}
    frontier[1] = { hex = start, priority = 0 }

    local path_so_far = {}
    path_so_far[start.x] = {}
    path_so_far[start.x][start.y] = 0

    local made_it = false
    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)

        if current.hex == goal then
            made_it = true
            break
        end

        for _,next_ in pairs(map.neighbours(current.hex)) do
            local new_cost = map_get(path_so_far, current.hex.x, current.hex.y) + cost_f(map, current.hex, next_)
            local next_cost = map_get(path_so_far, next_.x, next_.y)

            if not next_cost or new_cost < next_cost then
                map_set(path_so_far, next_.x, next_.y, new_cost)
                local priority = new_cost + heuristic(goal, next_)
                table.insert(frontier, { hex = next_, priority = priority })
                map_set(path, next_.x, next_.y, current)
            end
        end
    end

    return path, made_it
end

