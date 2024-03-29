
do
    -- add padding, because we terraform the very outer edge and it looks ugly, so hide it
    -- should be an even number to preserve a 'true' center
    local padding = 4

    -- the size of the grid should basically always be constant (i think),
    -- but different aspect ratios complicate this in an annoying way
    -- grid width should be ~== height * 3 / 2
    HEX_GRID_WIDTH = 33 + padding
    HEX_GRID_HEIGHT = 23 + padding

    HEX_GRID_DIMENSIONS = vec2(HEX_GRID_WIDTH, HEX_GRID_HEIGHT)

    HEX_GRID_CENTER = evenq_to_hex(vec2(math.floor(HEX_GRID_WIDTH/2)
                                     , -math.floor(HEX_GRID_HEIGHT/2)))

    -- pixel distance from hex centerpoint to any vertex
    -- given a grid width gx, and window width wx, what's the smallest size a hex can be to fill the whole screen?
    -- wx / (gx * 3 / 2)
    HEX_SIZE = win.width / ((HEX_GRID_WIDTH - padding) * 3 / 2)
    hex_set_default_size(vec2(HEX_SIZE))

    HEX_PIXEL_WIDTH = hex_width(HEX_SIZE, HEX_ORIENTATION.FLAT)
    HEX_PIXEL_HEIGHT = hex_height(HEX_SIZE, HEX_ORIENTATION.FLAT)
    HEX_PIXEL_DIMENSIONS = vec2(HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)

    local hhs = hex_horizontal_spacing(HEX_SIZE)
    local hvs = hex_vertical_spacing(HEX_SIZE)

    -- number of 'spacings' on the grid == number of cells - 1
    HEX_GRID_PIXEL_WIDTH = (HEX_GRID_WIDTH - 1) * hhs
    HEX_GRID_PIXEL_HEIGHT = (HEX_GRID_HEIGHT - 1) * hvs

    HEX_GRID_PIXEL_DIMENSIONS = vec2(HEX_GRID_PIXEL_WIDTH
                                   , HEX_GRID_PIXEL_HEIGHT)
end

-- amulet puts 0,0 in the middle of the screen
-- transform coordinates by this to pretend 0,0 is elsewhere
-- note this is isn't necessary when adding stuff to the worldspace in general,
-- because the worldspace parent node should be translated by this constant
WORLDSPACE_COORDINATE_OFFSET = -HEX_GRID_PIXEL_DIMENSIONS/2

-- the outer edges of the map are not interactable
-- the interactable region is defined with this function and constant
HEX_GRID_INTERACTABLE_REGION_MARGIN = vec2(3, 4)
function evenq_is_in_interactable_region(evenq)
    return point_in_rect(evenq, {
        x1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN.x,
        x2 = HEX_GRID_WIDTH  - HEX_GRID_INTERACTABLE_REGION_MARGIN.x,
        y1 =                   HEX_GRID_INTERACTABLE_REGION_MARGIN.y,
        y2 = HEX_GRID_HEIGHT - HEX_GRID_INTERACTABLE_REGION_MARGIN.y
    })
end

function map_elevation_to_tile_type(elevation)
    if elevation < -0.5 then -- lowest elevation
        return "Water"

    elseif elevation < 0 then -- med-low elevation
        return "Ground - Grass"

    elseif elevation < 0.5 then -- med-high elevation
        return "Ground - Dirt"

    elseif elevation <= 1 then     -- high elevation
        return "Mountain"

    else
        -- not a normal elevation? not sure when this happens
        return "n/a"
    end
end

function is_water_elevation(elevation) return elevation < -0.5 end
function is_mountain_elevation(elevation) return elevation >= 0.5 end

function tile_is_medium_elevation(tile)
    return tile.elevation >= -0.5 and tile.elevation < 0.5
end

function grid_heuristic(source, target)
    return math.distance(source, target)
end

HEX_GRID_MINIMUM_ELEVATION = -1
HEX_GRID_MAXIMUM_ELEVATION = 1
function grid_cost(map, from, to)
    local t1, t2 = hex_map_get(map, from), hex_map_get(map, to)

    return 2 + math.abs(t1.elevation)^0.5 - math.abs(t2.elevation)^0.5
end

function grid_neighbours(map, hex)
    return table.filter(hex_neighbours(hex), function(_hex)
        local tile = hex_map_get(map, _hex)
        return tile and tile_is_medium_elevation(tile)
    end)
end

function generate_flow_field(map, start)
    return hex_dijkstra(map, start, nil, grid_neighbours, grid_cost)
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

function building_tower_breaks_flow_field(tower_type, hex)
    local original_elevations = {}
    local all_impassable = true
    local hexes = hex_spiral_map(hex, get_tower_size(tower_type) - 1)
    for _,h in pairs(hexes) do
        local tile = hex_map_get(game_state.map, h)

        if all_impassable and mob_can_pass_through(nil, h) then
            all_impassable = false
        end

        table.insert(original_elevations, tile.elevation)

        -- making the tile's elevation very large *should* make it unwalkable
        tile.elevation = math.huge
    end

    -- if no mobs can pass over any of the tiles we're building on
    -- there is no need to regenerate the flow field, or do anything more
    -- (besides return all the tile's elevations back to their original game_state)
    if all_impassable then
        for i,h in pairs(hexes) do
            hex_map_get(game_state.map, h).elevation = original_elevations[i]
        end
        return false
    end

    local flow_field = generate_flow_field(game_state.map, HEX_GRID_CENTER)
    local result = not hex_map_get(flow_field, 0, 0)

    for i,h in pairs(hexes) do
        hex_map_get(game_state.map, h).elevation = original_elevations[i]
    end

    return result, flow_field
end

function map_elevation_to_color(elevation)
    if elevation < -0.5 then -- lowest elevation
        return COLORS.WATER{ a = (elevation + 1.4) / 2 + 0.2 }

    elseif elevation < 0 then -- med-low elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.8) / 2 + 0.3 }

    elseif elevation < 0.5 then -- med-high elevation
        return math.lerp(COLORS.DIRT, COLORS.GRASS, elevation + 0.5){ a = (elevation + 1.6) / 2 + 0.3 }

    elseif elevation <= 1 then     -- high elevation
        return COLORS.MOUNTAIN{ ra = elevation }

    else
        -- this only happens when loading a save, and the tile has an elevation that's
        -- higher that anything here. it isn't really of any consequence though
        return vec4(0)
    end
end

do
    local s60 = math.sin(math.rad(60))
    local c60 = math.cos(math.rad(60))
    local radius = HEX_SIZE

    -- adds a pair of quads constructed to quads via quads:add_quad that draws a hexagon
    function make_hex_quads_node(quads, position, color, uvs)
        local p = position or vec2(0)

        quads:add_quad{
            vert = {
                p.x - c60 * radius, p.y + s60 * radius,
                p.x - radius, p.y,
                p.x + radius, p.y,
                p.x + c60 * radius, p.y + s60 * radius
            },
            uv = am.vec2_array{
                vec2(0, 0),
                vec2(0, 0.5),
                vec2(1, 0.5),
                vec2(1, 0)
            },
            color = color or vec4(1),
        }
        quads:add_quad{
            vert = {
                p.x - radius, p.y,
                p.x - c60 * radius, p.y - s60 * radius,
                p.x + c60 * radius, p.y - s60 * radius,
                p.x + radius, p.y
            },
            uv = am.vec2_array{
                vec2(0, 0.5),
                vec2(0, 1),
                vec2(1, 1),
                vec2(1, 0.5)
            },
            color = color or vec4(1),
        }
    end
end

local HEX_VSHADER_PROGRAM = [[
    precision highp float;

    attribute vec2 uv;
    attribute vec2 vert;
    attribute vec4 color;

    uniform mat4 MV;
    uniform mat4 P;

    varying vec2 v_uv;
    varying vec4 v_color;

    void main() {
        v_uv = uv;
        v_color = color;
        gl_Position = P * MV * vec4(vert, 0.0, 1.0);
    }
]]
local HEX_FSHADER_PROGRAM = [[
    precision mediump float;

    uniform sampler2D texture;

    varying vec2 v_uv;
    varying vec4 v_color;

    void main() {
        gl_FragColor = texture2D(texture, v_uv) * v_color;
    }
]]
function make_hex_shader_program_node()
    return am.program(HEX_VSHADER_PROGRAM, HEX_FSHADER_PROGRAM)
end
function world_layer_tag(i)
    return string.format("layer-%d", i)
end
function make_hex_grid_scene(map, do_generate_flow_field)
    local world = am.group():tag"world"

    for i = 0, 10 do
        world:append(am.group():tag(world_layer_tag(i)))
    end

    local floor = world(world_layer_tag(0))
    local quads = am.quads(map.size * 2, {"vert", "vec2", "uv", "vec2", "color", "vec4"})
    quads.usage = "static" -- see am.buffer documentation, hint to gpu
    local prog = make_hex_shader_program_node()

    for i,_ in pairs(map) do
        for j,tile in pairs(map[i]) do
            local v = vec2(i, j)
            local p = hex_to_pixel(v)
            local d = math.distance(p, hex_to_pixel(HEX_GRID_CENTER)) -- distance to center

            -- light shading on edge cells, scaled by distance to center
            local mask = vec4(d/(HEX_GRID_PIXEL_WIDTH * 6))
            local color = map_elevation_to_color(tile.elevation) - mask

            make_hex_quads_node(quads, p, color)
        end
    end

    local texture = TEXTURES.WHITE
    floor:append((am.blend("alpha") ^ am.use_program(prog) ^ am.bind{ texture = texture } ^ quads))

    -- add the magenta diamond that represents 'home'
    floor:append(
        am.translate(hex_to_pixel(HEX_GRID_CENTER, vec2(HEX_SIZE)))
        ^ pack_texture_into_sprite(TEXTURES.GEM1, HEX_SIZE, HEX_SIZE*1.1)
    )

    if do_generate_flow_field then
        apply_flow_field(map, generate_flow_field(map, HEX_GRID_CENTER), world)
    end

    return am.translate(WORLDSPACE_COORDINATE_OFFSET) ^ world
end

function random_map(seed)
    local map = hex_rectangular_map(
        HEX_GRID_DIMENSIONS.x,
        HEX_GRID_DIMENSIONS.y,
        HEX_ORIENTATION.FLAT,
        seed,
        true
    )
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

            hex_map_set(map, i, j, {
                elevation = noise
            })
        end
    end

    return map
end

function default_map_editor_map(seed)
    if seed then
        return random_map(seed)
    end

    -- if there's no seed then we want a map w/ all noise values = 0
    local map = hex_rectangular_map(
        HEX_GRID_DIMENSIONS.x,
        HEX_GRID_DIMENSIONS.y,
        HEX_ORIENTATION.FLAT,
        seed,
        false
    )

    for i,_ in pairs(map) do
        for j,noise in pairs(map[i]) do
            hex_map_set(map, i, j, {
                elevation = noise
            })
        end
    end

    return map
end

