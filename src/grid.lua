

require "gui"
require "hexyz"

HEX_SIZE = 20

-- with 1920x1080, this is the minimal dimensions to cover the screen (65x33)
-- odd numbers are important because we want a 'true' center
HEX_GRID_WIDTH = 65
HEX_GRID_HEIGHT = 33
HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

-- leaving y == 0 makes this the center in hex coordinates
HEX_GRID_CENTER = vec2(math.floor(HEX_GRID_DIMENSIONS.x/2), 0)

-- index is hex coordinates [x][y]
-- { { elevation, node, etc. } }
HEX_MAP = {}

local function grid_pixel_dimensions()
    local hhs = hex_horizontal_spacing(HEX_SIZE)
    local hvs = hex_vertical_spacing(HEX_SIZE)

    -- number of 'spacings' on the grid == number of cells - 1
    return vec2((HEX_GRID_WIDTH - 1) * hhs
              , (HEX_GRID_HEIGHT - 1) * hvs)
end

GRID_PIXEL_DIMENSIONS = grid_pixel_dimensions()


HEX_GRID_INTERACTABLE_REGION_PADDING = 2
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

-- map elevation to appropriate tile color.
function color_at(elevation)
    if elevation < -0.5 then -- lowest elevation : impassable
        return COLORS.BLUE_STONE{ a = (elevation + 1.4) / 2 + 0.2 }

    elseif elevation < 0 then -- med-low elevation : passable
        return math.lerp(COLORS.MYRTLE, COLORS.BROWN_POD, elevation + 0.5){ a = (elevation + 1.8) / 2 + 0.2 }

    elseif elevation < 0.5 then -- med-high elevation : passable
        return math.lerp(COLORS.MYRTLE, COLORS.BROWN_POD, elevation + 0.5){ a = (elevation + 1.6) / 2 + 0.2 }

    elseif elevation < 1 then     -- highest elevation : impassable
        return COLORS.BOTTLE_GREEN{ a = (elevation + 1.0) / 2 + 0.2 }

    else
        log('bad elevation'); return vec4(0)
    end
end

function grid_neighbours(map, hex)
    return table.filter(hex_neighbours(hex), function(_hex)
        return map.get(_hex.x, _hex.y)
    end)
end

function random_map(seed)
    local map = rectangular_map(HEX_GRID_DIMENSIONS.x, HEX_GRID_DIMENSIONS.y, seed)
    math.randomseed(map.seed)

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
                node = node
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
        map[hex.x][hex.y].node.color = color_at(0)
    end
    world:append(am.circle(hex_to_pixel(HEX_GRID_CENTER), HEX_SIZE/2, COLORS.MAGENTA, 4))

    WORLDSPACE_COORDINATE_OFFSET = -GRID_PIXEL_DIMENSIONS/2
    return map, am.translate(WORLDSPACE_COORDINATE_OFFSET)
                ^ world:tag"world"
end

