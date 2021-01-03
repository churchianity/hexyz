
require "colors"
require "gui"

HEX_SIZE = 20
HEX_GRID_WIDTH = 65
HEX_GRID_HEIGHT = 33
HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

-- this is in hex coordinates
HEX_GRID_CENTER = vec2(math.floor(HEX_GRID_DIMENSIONS.x/2), 0)

-- index is hex coordinates [x][y]
-- { { elevation, sprite, tile } }
HEX_MAP = {}

function grid_pixel_dimensions()
    local hhs = hex_horizontal_spacing(HEX_SIZE)
    local hvs = hex_vertical_spacing(HEX_SIZE)

    -- number of 'spacings' on the grid == number of cells - 1
    return vec2((HEX_GRID_DIMENSIONS.x - 1) * hhs
              , (HEX_GRID_DIMENSIONS.y - 1) * hvs)
end

GRID_PIXEL_DIMENSIONS = grid_pixel_dimensions()
WORLDSPACE_COORDINATE_OFFSET = -GRID_PIXEL_DIMENSIONS/2

-- convience function for when getting a tile at x,y could fail
function get_tile(x, y)
    return HEX_MAP[x] and HEX_MAP[x][y]
end

-- map elevation to appropriate tile color.
function color_at(elevation)
    if elevation < -0.5 then -- lowest elevation : impassable
        return COLORS.BLUE_STONE{ a = (elevation + 1.4) / 2 + 0.2 }

    elseif elevation < 0 then -- med-low elevation : passable
        return COLORS.MYRTLE{ a = (elevation + 1.8) / 2 + 0.2 }

    elseif elevation < 0.5 then -- med-high elevation : passable
        return COLORS.BROWN_POD{ a = (elevation + 1.6) / 2 + 0.2 }

    elseif elevation < 1 then     -- highest elevation : impassable
        return COLORS.BOTTLE_GREEN{ a = (elevation + 1.0) / 2 + 0.2 }
    else
        log('bad elevation')
        return vec4(0)
    end
end

function generate_flow_field(start)
    local frontier = { start }
    local came_from = {}
    came_from[start.x] = {}
    came_from[start.x][start.y] = true

    while not (#frontier == 0) do
        local current = table.pop(frontier)
        log(current)

        for _,neighbour in pairs(hex_neighbours(current)) do
            if get_tile(neighbour.x, neighbour.y) then
                if not (came_from[neighbour.x] and came_from[neighbour.x][neighbour.y]) then
                    log("hi")
                    if true then return came_from end
                    table.insert(frontier, neighbour)
                    came_from[neighbour.x] = {}
                    came_from[neighbour.x][neighbour.y] = current
                end
            end
        end
    end

    return came_from
end

function random_map(seed, do_seed_rng)
    local elevation_map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, seed)

    if do_seed_rng then math.randomseed(elevation_map.seed) end

    HEX_MAP = {}
    local world = am.group():tag"world"
    for i,_ in pairs(elevation_map) do
        HEX_MAP[i] = {}
        for j,elevation in pairs(elevation_map[i]) do

            local off = hex_to_evenq(vec2(i, j))
            local mask = vec4(0, 0, 0, math.max(((off.x - HEX_GRID_DIMENSIONS.x/2) / HEX_GRID_DIMENSIONS.x) ^ 2
                                             , ((-off.y - HEX_GRID_DIMENSIONS.y/2) / HEX_GRID_DIMENSIONS.y) ^ 2))
            local color = color_at(elevation) - mask

            local node = am.circle(hex_to_pixel(vec2(i, j)), HEX_SIZE, color, 6)

            HEX_MAP[i][j] = {
                elevation = elevation,
                sprite = node,
                tile = {}
            }

            world:append(node)
        end
    end

    -- the center of the map in some radius is always considered 'passable' terrain and is home base
    -- terraform this area to ensure it's passable
    -- @NOTE no idea why the y-coord doesn't need to be transformed
    local home = spiral_map(HEX_GRID_CENTER, 3)
    for _,hex in pairs(home) do
        HEX_MAP[hex.x][hex.y].elevation = 0
        HEX_MAP[hex.x][hex.y].sprite.color = color_at(0)
        world:append(am.circle(hex_to_pixel(vec2(hex.x, hex.y)), HEX_SIZE/2, COLORS.MAGENTA, 4))
    end

    return am.translate(WORLDSPACE_COORDINATE_OFFSET)
           ^ world:tag"world"
end

function grid_neighbours(hex)
    return table.filter(hex_neighbours(hex), function(_hex) return get_tile(_hex.x, _hex.y) end)
end

