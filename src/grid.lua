

-- distance from hex centerpoint to any vertex
HEX_SIZE = 20

HEX_PIXEL_WIDTH = hex_width(HEX_SIZE, ORIENTATION.FLAT)
HEX_PIXEL_HEIGHT = hex_height(HEX_SIZE, ORIENTATION.FLAT)
HEX_PIXEL_DIMENSIONS = vec2(HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)

-- with 1920x1080, the minimal dimensions to cover the screen is 65x33
-- added 2 cell padding, because we terraform the very outer edge and it looks ugly, so hide it
-- odd numbers are important because we want a 'true' center
HEX_GRID_WIDTH = 67
HEX_GRID_HEIGHT = 35
HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

-- leaving y == 0 makes this the center in hex coordinates
HEX_GRID_CENTER = vec2(math.floor(HEX_GRID_WIDTH/2)
                     , 0)
                  -- , math.floor(HEX_GRID_HEIGHT/2))

HEX_GRID_MINIMUM_ELEVATION = -1
HEX_GRID_MAXIMUM_ELEVATION = 1

do
    local hhs = hex_horizontal_spacing(HEX_SIZE)
    local hvs = hex_vertical_spacing(HEX_SIZE)

    HEX_GRID_PIXEL_WIDTH = (HEX_GRID_WIDTH - 1) * hhs
    HEX_GRID_PIXEL_HEIGHT = (HEX_GRID_HEIGHT - 1) * hvs

    -- number of 'spacings' on the grid == number of cells - 1
    HEX_GRID_PIXEL_DIMENSIONS = vec2(HEX_GRID_PIXEL_WIDTH
                                   , HEX_GRID_PIXEL_HEIGHT)
end

-- amulet puts 0,0 in the middle of the screen
-- transform coordinates by this to pretend 0,0 is elsewhere
WORLDSPACE_COORDINATE_OFFSET = -HEX_GRID_PIXEL_DIMENSIONS/2

-- the outer edges of the map are not interactable
-- the interactable region is defined with this function and constant
HEX_GRID_INTERACTABLE_REGION_MARGIN = 4
function evenq_is_in_interactable_region(evenq)
    return point_in_rect(evenq, {
        x1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN,
        x2 = HEX_GRID_WIDTH  - HEX_GRID_INTERACTABLE_REGION_MARGIN,
        y1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN,
        y2 = HEX_GRID_HEIGHT - HEX_GRID_INTERACTABLE_REGION_MARGIN
    })
end

function tile_is_medium_elevation(tile)
    return tile.elevation >= -0.5 and tile.elevation < 0.5
end

function color_at(elevation)
    if elevation < -0.5 then -- lowest elevation
        return COLORS.WATER{ a = (elevation + 1.4) / 2 + 0.2 }

    elseif elevation < 0 then -- med-low elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.8) / 2 + 0.3 }

    elseif elevation < 0.5 then -- med-high elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.6) / 2 + 0.3 }

    elseif elevation < 1 then     -- high elevation
        return COLORS.MOUNTAIN{ ra = elevation }
    end
end

function grid_heuristic(source, target)
    return math.distance(source, target)
end

function grid_cost(map, from, to)
    local t1, t2 = map.get(from.x, from.y), map.get(to.x, to.y)

    -- i have no fucking clue why, but adding +0.2 to the end of this fixes a bug where sometimes two (or more)
    -- equivalent paths are found and mobs backpedal trying to decide between them
    -- (seed 2014 at time of writing has this at the bottom)
    local elevation_epsilon = HEX_GRID_MAXIMUM_ELEVATION - HEX_GRID_MINIMUM_ELEVATION + 0.2
    local elevation_cost = math.abs(math.abs(t1.elevation)^0.5
                                  - math.abs(t2.elevation)^0.5)

    local epsilon = elevation_epsilon
    local cost = elevation_cost

    return epsilon - cost
end

function generate_flow_field(map, start)
    return dijkstra(map, start, nil, grid_cost)
end

function apply_flow_field(map, flow_field, world)
    local flow_field_hidden = world and world"flow_field" and world"flow_field".hidden or true
    if world and world"flow_field" then
        world:remove"flow_field"
    end

    local overlay_group = am.group():tag"flow_field"
    for i,_ in pairs(map) do
        for j,f in pairs(map[i]) do
            local flow = hex_map_get(flow_field, i, j)

            if flow then
                map[i][j].priority = flow.priority

                overlay_group:append(am.translate(hex_to_pixel(vec2(i, j)))
                                     ^ am.text(string.format("%.1f", flow.priority * 10)))
            else
                map[i][j].priority = nil
            end
        end
    end

    if world then
        overlay_group.hidden = flow_field_hidden
        world:append(overlay_group)
    end
end

function making_hex_unwalkable_breaks_flow_field(hex, tile)
    if not mob_can_pass_through(nil, hex, tile) then
        return false
    end

    local original_elevation = tile.elevation
    -- making the tile's elevation very large *should* make it unwalkable
    tile.elevation = 999

    local flow_field = generate_flow_field(state.map, HEX_GRID_CENTER)
    local result = not hex_map_get(flow_field, 0, 0)
    tile.elevation = original_elevation
    return result, flow_field
end

function random_map(seed)
    local map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, seed)
    math.randomseed(map.seed)

    -- the world's appearance relies largely on a backdrop which can be scaled in
    -- tone to give the appearance of light or darkness
    -- @NOTE replace this with a shader program
    -- interestingly, if it's colored white, it almost gives the impression of a winter biome
    local neg_mask = am.rect(0, 0, HEX_GRID_PIXEL_WIDTH, HEX_GRID_PIXEL_HEIGHT, COLORS.TRUE_BLACK):tag"negative_mask"

    local world = am.group(neg_mask):tag"world"
    for i,_ in pairs(map) do
        for j,noise in pairs(map[i]) do
            local evenq = hex_to_evenq(vec2(i, j))

            if  evenq.x == 0 or  evenq.x == (HEX_GRID_WIDTH - 1)
            or -evenq.y == 0 or -evenq.y == (HEX_GRID_HEIGHT - 1) then
                -- if we're on an edge -- terraform edges to be passable
                noise = 0

            elseif j == HEX_GRID_CENTER.y and i == HEX_GRID_CENTER.x then
                -- also terraform the center of the grid to be passable
                -- very infrequently, but still sometimes it is not medium elevation
                noise = 0

            else
                -- scale noise to be closer to 0 the closer we are to the center
                -- @NOTE i don't know if this 100% of the time makes the center tile passable, but it seems to 99.9+% of the time
                -- @NOTE it doesn't. seed: 1835, 2227?
                local nx, ny = evenq.x/HEX_GRID_WIDTH - 0.5, -evenq.y/HEX_GRID_HEIGHT - 0.5
                local d = (nx^2 + ny^2)^0.5 / 0.5^0.5
                noise = noise * d^0.125 -- arbitrary, seems to work good
            end

            -- light shading on edge cells
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

    getmetatable(map).__index.neighbours = function(hex)
        return table.filter(hex_neighbours(hex), function(_hex)
            local tile = map.get(_hex.x, _hex.y)
            return tile and tile_is_medium_elevation(tile)
        end)
    end

    apply_flow_field(map, generate_flow_field(map, HEX_GRID_CENTER), world)

    return map, am.translate(WORLDSPACE_COORDINATE_OFFSET) ^ world
end

