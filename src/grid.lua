

-- distance from hex centerpoint to any vertex
HEX_SIZE = 20
HEX_PIXEL_SIZE = vec2(hex_width(HEX_SIZE, ORIENTATION.FLAT)
                    , hex_height(HEX_SIZE, ORIENTATION.FLAT))

-- with 1920x1080, this is the minimal dimensions to cover the screen (65x33)
-- @NOTE added 2 cell padding, because we terraform the very outer edge and it looks ugly
-- odd numbers are important because we want a 'true' center
HEX_GRID_WIDTH = 67
HEX_GRID_HEIGHT = 35
HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

-- leaving y == 0 makes this the center in hex coordinates
HEX_GRID_CENTER = vec2(math.floor(HEX_GRID_WIDTH/2)
                     , 0)
                    -- math.floor(HEX_GRID_HEIGHT/2))

-- index is hex coordinates [x][y]
-- { { elevation, node, etc. } }
HEX_MAP = {}

do
    local hhs = hex_horizontal_spacing(HEX_SIZE)
    local hvs = hex_vertical_spacing(HEX_SIZE)

    -- number of 'spacings' on the grid == number of cells - 1
    GRID_PIXEL_DIMENSIONS = vec2((HEX_GRID_WIDTH - 1) * hhs
                               , (HEX_GRID_HEIGHT - 1) * hvs)
end

-- amulet puts 0,0 in the middle of the screen
-- transform coordinates by this to pretend 0,0 is elsewhere
WORLDSPACE_COORDINATE_OFFSET = -GRID_PIXEL_DIMENSIONS/2

-- the outer edges of the map are not interactable, most action occurs in the center
HEX_GRID_INTERACTABLE_REGION_PADDING = 4
function is_interactable(tile, evenq)
    return point_in_rect(evenq, {
        x1 =                   HEX_GRID_INTERACTABLE_REGION_PADDING,
        x2 = HEX_GRID_WIDTH  - HEX_GRID_INTERACTABLE_REGION_PADDING,
        y1 =                   HEX_GRID_INTERACTABLE_REGION_PADDING,
        y2 = HEX_GRID_HEIGHT - HEX_GRID_INTERACTABLE_REGION_PADDING
    })
end

function is_passable(tile, mob)
    return tile.elevation > -0.5 and tile.elevation < 0.5
end

-- map elevation to appropriate color
function color_at(elevation)
    if elevation < -0.5 then -- lowest elevation
        return COLORS.WATER{ a = (elevation + 1.4) / 2 + 0.2 }

    elseif elevation < 0 then -- med-low elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.8) / 2 + 0.2 }

    elseif elevation < 0.5 then -- med-high elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.6) / 2 + 0.2 }

    elseif elevation < 1 then     -- high elevation
        return COLORS.MOUNTAIN{ ra = elevation }
    end
end

local function grid_heuristic(source, target)
    return math.distance(source, target)
end

local function grid_cost(map, from, to)
    local t1, t2 = map.get(from.x, from.y), map.get(to.x, to.y)
    if t2.elevation < -0.5 or t2.elevation >= 0.5
    or t1.elevation < -0.5 or t1.elevation >= 0.5 then return 999 end
    return math.abs(math.abs(t1.elevation)^0.5 - math.abs(t2.elevation)^0.5)
end

local function generate_flow_field(map, start)
    return dijkstra(map, start, nil, grid_cost)
end

function random_map(seed)
    local map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, seed)
    math.randomseed(map.seed)

    local world = am.group()
    for i,_ in pairs(map) do
        for j,noise in pairs(map[i]) do
            local evenq = hex_to_evenq(vec2(i, j))

            -- check if we're on an edge -- terraform edges to be passable
            if  evenq.x == 0 or  evenq.x == (HEX_GRID_WIDTH - 1)
            or -evenq.y == 0 or -evenq.y == (HEX_GRID_HEIGHT - 1) then
                noise = 0

            else
                -- scale noise to be closer to 0 the closer we are to the center
                -- @NOTE i don't know if this 100% of the time makes the center tile passable, but it seems to 99.9+% of the time
                local nx, ny = evenq.x/HEX_GRID_WIDTH - 0.5, -evenq.y/HEX_GRID_HEIGHT - 0.5
                local d = (nx^2 + ny^2)^0.5 / 0.5^0.5
                noise = noise * d^0.125 -- arbitrary, seems to work good
            end

            -- light shading on edge cells @TODO replace this with a skylight, that can move
            local mask = vec4(0, 0, 0, math.max(((evenq.x - HEX_GRID_WIDTH/2) / HEX_GRID_WIDTH) ^ 2
                                             , ((-evenq.y - HEX_GRID_HEIGHT/2) / HEX_GRID_HEIGHT) ^ 2))
            local color = color_at(noise) - mask

            local node = am.translate(hex_to_pixel(vec2(i, j)))
                         ^ am.circle(vec2(0), HEX_SIZE, color, 6)

            map.set(i, j, {
                elevation = noise,
                node = node
            })

            world:append(node)
        end
    end

    local flow_field = generate_flow_field(map, HEX_GRID_CENTER)
    for i,_ in pairs(flow_field) do
        for j,priority in pairs(flow_field[i]) do
            if priority then
                map[i][j].priority = priority.priority
            end
        end
    end

    world:append(draw_priority_overlay(map))

    world:append(am.circle(hex_to_pixel(HEX_GRID_CENTER), HEX_SIZE/2, COLORS.MAGENTA, 4))

    return map, am.translate(WORLDSPACE_COORDINATE_OFFSET)
                ^ world:tag"world"
end

function draw_priority_overlay(map)
    local priority_overlay = am.group():tag"priority_overlay"
    for i,_ in pairs(map) do
        for j,tile in pairs(map[i]) do
            if tile then
                priority_overlay:append(am.translate(hex_to_pixel(vec2(i, j)))
                                        ^ am.text(string.format("%.1f", tile.priority or 0)))
            end
        end
    end
    return priority_overlay
end


