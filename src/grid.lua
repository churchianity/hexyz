

require "gui"
require "hexyz"

HEX_SIZE = 20

-- with 1920x1080, this is the minimal dimensions to cover the screen (65x33)
-- @NOTE added 2 cell padding, because we terraform the very outer edge and it looks ugly
-- odd numbers are important because we want a 'true' center
HEX_GRID_WIDTH = 67
HEX_GRID_HEIGHT = 35
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

    else
        log('bad elevation'); return vec4(0)
    end
end

-- hex_neighbours returns all coordinate positions that could be valid for a map extending infinite in all directions
-- grid_neighbours only gets you the neighbours that are actually in the grid
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
            local evenq = hex_to_evenq(vec2(i, j))

            -- check if we're on an edge -- terraform edges to be passable
            if  evenq.x == 0 or  evenq.x == (HEX_GRID_WIDTH - 1)
            or -evenq.y == 0 or -evenq.y == (HEX_GRID_HEIGHT - 1) then
                noise = 0

            else
                -- scale noise to be closer to 0 the closer we are to the center
                -- @NOTE i don't know if this 100% of the time makes the center tile passable, but it probably does 99.9+% of the time
                local nx, ny = evenq.x/HEX_GRID_WIDTH - 0.5, -evenq.y/HEX_GRID_HEIGHT - 0.5
                local d = math.sqrt(nx^2 + ny^2) / math.sqrt(0.5)
                noise = noise * d^0.125 -- arbitrary, seems to work good
            end

            -- light shading on edge cells
            local mask = vec4(0, 0, 0, math.max(((evenq.x - HEX_GRID_WIDTH/2) / HEX_GRID_WIDTH) ^ 2
                                             , ((-evenq.y - HEX_GRID_HEIGHT/2) / HEX_GRID_HEIGHT) ^ 2))
            local color = color_at(noise) - mask

            local node = am.circle(hex_to_pixel(vec2(i, j)), HEX_SIZE, color, 6)

            map.set(i, j, {
                elevation = noise,
                node = node
            })

            world:append(node)
        end
    end

    world:append(am.circle(hex_to_pixel(HEX_GRID_CENTER), HEX_SIZE/2, COLORS.MAGENTA, 4))

    WORLDSPACE_COORDINATE_OFFSET = -GRID_PIXEL_DIMENSIONS/2
    return map, am.translate(WORLDSPACE_COORDINATE_OFFSET)
                ^ world:tag"world"
end

