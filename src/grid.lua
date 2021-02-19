

-- distance from hex centerpoint to any vertex
HEX_SIZE = 26

HEX_PIXEL_WIDTH = hex_width(HEX_SIZE, ORIENTATION.FLAT)
HEX_PIXEL_HEIGHT = hex_height(HEX_SIZE, ORIENTATION.FLAT)
HEX_PIXEL_DIMENSIONS = vec2(HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)

do
    -- add padding, because we terraform the very outer edge and it looks ugly, so hide it
    local padding = 3

    HEX_GRID_WIDTH = math.floor(win.width / (HEX_PIXEL_WIDTH + HEX_SIZE) * 2) + padding
    HEX_GRID_HEIGHT = math.floor(win.height / HEX_PIXEL_HEIGHT) + padding

    -- odd numbers are important because we want a 'true' center
    if HEX_GRID_WIDTH % 2 == 0 then
        HEX_GRID_WIDTH = HEX_GRID_WIDTH + 1
    end
    if HEX_GRID_HEIGHT % 2 == 0 then
        HEX_GRID_HEIGHT = HEX_GRID_HEIGHT + 1
    end

    HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

    -- leaving y == 0 makes this the center in hex/cube coordinates
    -- assuming that our dimensions are correct (odd numbers)
    HEX_GRID_CENTER = vec2(math.floor(HEX_GRID_WIDTH/2)
                         , 0)
end

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
-- note this is isn't necessary when adding stuff to the worldspace in general,
-- because the whole worldspace is translated by this constant
WORLDSPACE_COORDINATE_OFFSET = -HEX_GRID_PIXEL_DIMENSIONS/2

-- the outer edges of the map are not interactable
-- the interactable region is defined with this function and constant
HEX_GRID_INTERACTABLE_REGION_MARGIN = 3
function evenq_is_in_interactable_region(evenq)
    return point_in_rect(evenq, {
        x1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN,
        x2 = HEX_GRID_WIDTH  - HEX_GRID_INTERACTABLE_REGION_MARGIN,
        y1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN,
        y2 = HEX_GRID_HEIGHT - HEX_GRID_INTERACTABLE_REGION_MARGIN
    })
end

function is_water_elevation(elevation)
    return elevation < -0.5
end

function is_mountain_elevation(elevation)
    return elevation >= 0.5
end

function tile_is_medium_elevation(tile)
    return tile.elevation >= -0.5 and tile.elevation < 0.5
end

function grid_heuristic(source, target)
    return math.distance(source, target)
end

function grid_cost(map, from, to)
    local t1, t2 = map_get(map, from), map_get(map, to)

    -- i have no fucking clue why, but adding +0.2 to the end of this fixes a bug where sometimes two (or more)
    -- equivalent paths are found and mobs backpedal trying to decide between them
    -- (seed 2014 at time of writing has this at the bottom)
    local elevation_epsilon = HEX_GRID_MAXIMUM_ELEVATION - HEX_GRID_MINIMUM_ELEVATION + 0.2
    local elevation_cost = math.abs(math.abs(t1.elevation)^0.5
                                  - math.abs(t2.elevation)^0.5)

    local epsilon = elevation_epsilon
    local cost = elevation_cost

    return 1
end

function grid_neighbours(map, hex)
    return table.filter(hex_neighbours(hex), function(_hex)
        local tile = map_get(map, _hex)
        return tile and tile_is_medium_elevation(tile)
    end)
end

function generate_flow_field(map, start)
    return dijkstra(map, start, nil, grid_cost, grid_neighbours)
end

function apply_flow_field(map, flow_field, world)
    local flow_field_hidden = world and world"flow_field" and world"flow_field".hidden or true
    if world and world"flow_field" then
        world:remove"flow_field"
    end

    local overlay_group = am.group():tag"flow_field"
    for i,_ in pairs(map) do
        for j,f in pairs(map[i]) do
            local flow = map_get(flow_field, i, j)

            if flow then
                map[i][j].priority = flow.priority

                overlay_group:append(am.translate(hex_to_pixel(vec2(i, j), vec2(HEX_SIZE)))
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

-- some convenience functions for setting and retrieving values from a 2d sparse array
-- where the first index might return a nil value, causing the second second to crash the game
-- and where it's often the case that the indexer is a vec2
function map_get(map, hex, y)
    if y then return map[hex] and map[hex][y] end
    return map[hex.x] and map[hex.x][hex.y]
end

function map_set(map, hex, y, v)
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

function building_tower_breaks_flow_field(tower_type, hex)
    local original_elevations = {}
    local all_impassable = true
    local hexes = spiral_map(hex, get_tower_size(tower_type))
    for _,h in pairs(hexes) do
        local tile = map_get(state.map, h)

        if all_impassable and mob_can_pass_through(nil, h) then
            all_impassable = false
        end

        table.insert(original_elevations, tile.elevation)

        -- making the tile's elevation very large *should* make it unwalkable
        tile.elevation = math.huge
    end

    -- if no mobs can pass over any of the tiles we're building on
    -- there is no need to regenerate the flow field, or do anything more
    -- (besides return all the tile's elevations back to their original state)
    if all_impassable then
        for i,h in pairs(hexes) do
            map_get(state.map, h).elevation = original_elevations[i]
        end
        return false
    end

    local flow_field = generate_flow_field(state.map, HEX_GRID_CENTER)
    local result = not map_get(flow_field, 0, 0)

    for i,h in pairs(hexes) do
        map_get(state.map, h).elevation = original_elevations[i]
    end

    return result, flow_field
end

function make_hex_grid_scene(map)
    local function color_at(elevation)
        if elevation < -0.5 then -- lowest elevation
            return COLORS.WATER{ a = (elevation + 1.4) / 2 + 0.2 }

        elseif elevation < 0 then -- med-low elevation
            return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.8) / 2 + 0.3 }

        elseif elevation < 0.5 then -- med-high elevation
            return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.6) / 2 + 0.3 }

        elseif elevation < 1 then     -- high elevation
            return COLORS.MOUNTAIN{ ra = elevation }

        else
            -- @TODO probably fix... this only happens when loading a save, and the tile has an elevation that's
            -- higher that anything here
            return vec4(0.1)
        end
    end
    -- the world's appearance relies largely on a backdrop which can be scaled in
    -- tone to give the appearance of light or darkness
    -- @NOTE replace this with a shader program
    -- interestingly, if it's colored white, it almost gives the impression of a winter biome
    local neg_mask = am.rect(
        0,
        0,
        HEX_GRID_PIXEL_WIDTH,
        HEX_GRID_PIXEL_HEIGHT,
        COLORS.TRUE_BLACK
    )
    :tag"negative_mask"

    local world = am.group(neg_mask):tag"world"
    for i,_ in pairs(map) do
        for j,tile in pairs(map[i]) do
            local evenq = hex_to_evenq(vec2(i, j))

            -- light shading on edge cells
            local mask = vec4(0, 0, 0, math.max(((evenq.x - HEX_GRID_WIDTH/2) / HEX_GRID_WIDTH) ^ 2
                                             , ((-evenq.y - HEX_GRID_HEIGHT/2) / HEX_GRID_HEIGHT) ^ 2))

            local color = color_at(tile.elevation) - mask

            local node = am.translate(hex_to_pixel(vec2(i, j), vec2(HEX_SIZE)))
                        ^ am.circle(vec2(0), HEX_SIZE, color, 6)

            map_set(map, i, j, {
                elevation = tile.elevation,
                node = node
            })

            world:append(node)
        end
    end

    apply_flow_field(map, generate_flow_field(map, HEX_GRID_CENTER), world)

    return am.translate(WORLDSPACE_COORDINATE_OFFSET) ^ world
end

function random_map(seed)
    local map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, seed)
    math.randomseed(map.seed)

    -- there are some things about the generated map we'd like to change...
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

            map_set(map, i, j, {
                elevation = noise,
            })
        end
    end

    return map, make_hex_grid_scene(map)
end

