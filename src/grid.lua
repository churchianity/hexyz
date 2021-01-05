
require "hexyz"

HEX_SIZE = 20
HEX_GRID_WIDTH = 65  -- 65
HEX_GRID_HEIGHT = 33 -- 33
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

function random_map(seed, do_seed_rng)
    local map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, 105)
    --log(map.seed)

    if do_seed_rng then math.randomseed(elevation_map.seed) end

    local world = am.group():tag"world"
    for i,_ in pairs(map) do
        for j,noise in pairs(map[i]) do
            local off = hex_to_evenq(vec2(i, j))
            local mask = vec4(0, 0, 0, math.max(((off.x - HEX_GRID_DIMENSIONS.x/2) / HEX_GRID_DIMENSIONS.x) ^ 2
                                             , ((-off.y - HEX_GRID_DIMENSIONS.y/2) / HEX_GRID_DIMENSIONS.y) ^ 2))
            local color = color_at(noise) - mask

            local node = am.circle(hex_to_pixel(vec2(i, j)), HEX_SIZE, color, 6)

            map.set(i, j, {
                elevation = noise,
                sprite = node,
                tile = {}
            })

            world:append(node)
        end
    end

    -- the center of the map in some radius is always considered 'passable' terrain and is home base
    -- terraform this area to ensure it's passable
    -- @NOTE no idea why the y-coord doesn't need to be transformed
    -- @TODO @FIXME also terraform the edges of the map to be passable - it is theoretically possible to get maps where mobs can be stuck from the very beginning
    local home = spiral_map(HEX_GRID_CENTER, 3)
    for _,hex in pairs(home) do
        map[hex.x][hex.y].elevation = 0
        map[hex.x][hex.y].sprite.color = color_at(0)
        world:append(am.circle(hex_to_pixel(vec2(hex.x, hex.y)), HEX_SIZE/2, COLORS.MAGENTA, 4))
    end

    return map, am.translate(WORLDSPACE_COORDINATE_OFFSET)
                ^ world:tag"world"
end

