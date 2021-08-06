
do
    -- load tower data
    local tfile = am.load_script("data/towers.lua")
    local error_message
    if tfile then
        local status, result = pcall(tfile)

        if status then
            -- lua managed to run the file without syntax/runtime errors
            -- it's not garunteed to be what we want yet. check:
            local type_ = type(result)
            if type_ ~= "table" then
                error_message = "tower spec file should return a table, but we got " .. type_
                goto cleanup
            end

            TOWER_SPECS = result
        else
            -- runtime error - including syntax errors
            error_message = result
            goto cleanup
        end
    else
        -- file system related error - couldn't load the file
        error_message = "couldn't load the file"
    end

    ::cleanup::
    if error_message then
        log(error_message)
        -- @TODO no matter what fucked up, we should load defaults
    end
end

function get_tower_spec(tower_type)
    return TOWER_SPECS[tower_type]
end
function get_tower_name(tower_type)
    return TOWER_SPECS[tower_type].name
end
function get_tower_placement_rules_text(tower_type)
    return TOWER_SPECS[tower_type].placement_rules_text
end
function get_tower_short_description(tower_type)
    return TOWER_SPECS[tower_type].short_description
end
function get_tower_texture(tower_type)
    return TOWER_SPECS[tower_type].texture
end
function get_tower_icon_texture(tower_type)
    return TOWER_SPECS[tower_type].icon_texture
end
function get_tower_cost(tower_type)
    return TOWER_SPECS[tower_type].cost
end
function get_tower_range(tower_type)
    return TOWER_SPECS[tower_type].range
end
function get_tower_fire_rate(tower_type)
    return TOWER_SPECS[tower_type].fire_rate
end
function get_tower_size(tower_type)
    return TOWER_SPECS[tower_type].size
end

local function default_tower_weapon_target_acquirer(tower, tower_index)

end

local function make_tower_sprite(tower_type)
    return pack_texture_into_sprite(get_tower_texture(tower_type), HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)
end

function make_tower_node(tower_type)
    -- @TODO move to tower spec
    if tower_type == 4 then
        return make_tower_sprite(tower_type)

    elseif tower_type == 2 then
        return am.group{
                am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 5),
                am.rotate(game_state.time or 0)
                ^ pack_texture_into_sprite(TEXTURES.TOWER_HOWITZER, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2, COLORS.GREEN_YELLOW)
           }

    elseif tower_type == 3 then
        return am.group{
            am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 6),
            am.rotate(game_state.time or 0) ^ am.group{
                pack_texture_into_sprite(TEXTURES.TOWER_HOWITZER, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2) -- CHONK
            }
        }
    elseif tower_type == 7 then
        return am.group{
            make_tower_sprite(tower_type),
            am.particles2d{
                source_pos = vec2(0, 12),
                source_pos_var = vec2(2),
                start_size = 1,
                start_size_var = 1,
                end_size = 1,
                end_size_var = 1,
                angle = 0,
                angle_var = math.pi,
                speed = 1,
                speed_var = 2,
                life = 10,
                life_var = 1,
                start_color = COLORS.WHITE,
                start_color_var = vec4(0.1, 0.1, 0.1, 1),
                end_color = COLORS.SUNRAY,
                end_color_var = vec4(0.1),
                emission_rate = 4,
                start_particles = 4,
                max_particles = 200,
                warmup_time = 5
            }
        }
    elseif tower_type == 1 then
        return am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY{a=0.75}, 6)

    elseif tower_type == 5 then
        return am.circle(vec2(0), HEX_SIZE, COLORS.WATER{a=1}, 6)

    elseif tower_type == 6 then
        return make_tower_sprite(tower_type)
    end
end

do
    local tower_cursors = {}
    for i = 1, #TOWER_SPECS do
        local tower_sprite = make_tower_node(i)
        tower_sprite.color = COLORS.TRANSPARENT

        local coroutine_ = coroutine.create(function(node)
            local flash_on = {}
            local flash_off = {}
            while true do
                for _,n in node:child_pairs() do
                    table.insert(flash_on, am.tween(n, 1, { color = vec4(0.4) }))
                    table.insert(flash_off, am.tween(n, 1, { color = vec4(0) }))
                end
                am.wait(am.parallel(flash_on))
                am.wait(am.parallel(flash_off))
                flash_on = {}
                flash_off = {}
            end
        end)

        tower_cursors[i] = am.group{
            make_hex_cursor_node(get_tower_range(i), vec4(0), coroutine_),
            tower_sprite
        }
    end

    function get_tower_cursor(tower_type)
        return tower_cursors[tower_type]
    end
end

function tower_serialize(tower)
    local serialized = entity_basic_devectored_copy(tower)

    for i,h in pairs(tower.hexes) do
        serialized.hexes[i] = { h.x, h.y }
    end

    return am.to_json(serialized)
end

function tower_deserialize(json_string)
    local tower = entity_basic_json_parse(json_string)

    for i,h in pairs(tower.hexes) do
        tower.hexes[i] = vec2(tower.hexes[i][1], tower.hexes[i][2])
    end

    tower.update = get_tower_update_function(tower.type)
    tower.node = am.translate(tower.position) ^ make_tower_node(tower.type)

    return tower
end

function towers_on_hex(hex)
    local t = {}
    for tower_index,tower in pairs(game_state.towers) do
        if tower then
            for _,h in pairs(tower.hexes) do
                if h == hex then
                    table.insert(t, tower_index, tower)
                    break
                end
            end
        end
    end
    return t
end

function tower_on_hex(hex)
    return table.find(game_state.towers, function(tower)
        for _,h in pairs(tower.hexes) do
            if h == hex then return true end
        end
    end)
end

function tower_type_is_buildable_on(hex, tile, tower_type)
    -- this function gets polled a lot, and sometimes with nil/false tower types
    if not tower_type then return false end

    -- you can't build anything in the center
    if hex == HEX_GRID_CENTER then return false end

    local blocking_towers = {}
    local blocking_mobs = {}
    local has_water = false
    local has_mountain = false
    local has_ground = false

    for _,h in pairs(hex_spiral_map(hex, get_tower_size(tower_type))) do
        table.merge(blocking_towers, towers_on_hex(h))
        table.merge(blocking_mobs, mobs_on_hex(h))

        local tile = hex_map_get(game_state.map, h)
        -- this should always be true, unless it is possible to place a tower
        -- where part of the tower overflows the edge of the map
        if tile then
            if is_water_elevation(tile.elevation) then
                has_water = true

            elseif is_mountain_elevation(tile.elevation) then
                has_mountain = true

            else
                has_ground = true
            end
        end
    end

    local towers_blocking = table.count(blocking_towers) ~= 0
    local mobs_blocking = table.count(blocking_mobs) ~= 0
    local blocked = mobs_blocking or towers_blocking

    if tower_type == TOWER_TYPE.GATTLER then
        local has_mountain_neighbour = false
        local has_non_wall_non_moat_tower_neighbour = false
        for _,h in pairs(hex_neighbours(hex)) do
            local tile = hex_map_get(game_state.map, h)

            if tile and tile.elevation >=  0.5 then
                has_mountain_neighbour = true
                break
            end
        end
        return not (blocked or has_water or has_mountain)

    elseif tower_type == TOWER_TYPE.HOWITZER then
        local has_mountain_neighbour = false
        local has_non_wall_non_moat_tower_neighbour = false
        for _,h in pairs(hex_neighbours(hex)) do
            local towers = towers_on_hex(h)
            local wall_on_hex = false
            has_non_wall_non_moat_tower_neighbour = table.find(towers, function(tower)
                if tower.type == TOWER_TYPE.WALL then
                    wall_on_hex = true
                    return false

                elseif tower.type == TOWER_TYPE.MOAT then
                    return false
                end

                return true
            end)
            if has_non_wall_non_moat_tower_neighbour then
                break
            end

            local tile = hex_map_get(game_state.map, h)
            if not wall_on_hex and tile and tile.elevation >= 0.5 then
                has_mountain_neighbour = true
                break
            end
        end
        return not (blocked or has_water or has_mountain or has_mountain_neighbour or has_non_wall_non_moat_tower_neighbour)

    elseif tower_type == TOWER_TYPE.REDEYE then
        return not blocked
               and has_mountain

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        local has_water_neighbour = false
        for _,h in pairs(hex_neighbours(hex)) do
            local tile = hex_map_get(game_state.map, h)

            if tile and tile.elevation < -0.5 then
                has_water_neighbour = true
                break
            end
        end
        return not blocked
           and not has_mountain
           and not has_water
           and has_water_neighbour

    elseif tower_type == TOWER_TYPE.WALL then
        return not blocked and tile_is_medium_elevation(tile)

    elseif tower_type == TOWER_TYPE.MOAT then
        return not blocked and tile_is_medium_elevation(tile)
    end
end


function make_and_register_tower(hex, tower_type)
    local tower = make_basic_entity(
        hex,
        get_tower_update_function(tower_type)
    )

    tower.type = tower_type
    tower.node = am.translate(tower.position) ^ make_tower_node(tower_type)

    local spec = get_tower_spec(tower_type)
    tower.cost = spec.cost
    tower.range = spec.range
    tower.fire_rate = spec.fire_rate
    tower.last_shot_time = -spec.fire_rate -- lets the tower fire immediately upon being placed
    tower.size = spec.size
    if tower.size == 0 then
        tower.hexes = { tower.hex }
    else
        tower.hexes = hex_spiral_map(tower.hex, tower.size)
    end
    tower.height = spec.height

    for _,h in pairs(tower.hexes) do
        local tile = hex_map_get(game_state.map, h.x, h.y)
        tile.elevation = tile.elevation + tower.height
    end

    if tower.type == TOWER_TYPE.HOWITZER then
        tower.props.z = tower.height

    elseif tower.type == TOWER_TYPE.GATTLER then
        tower.props.z = tower.height

    elseif tower.type == TOWER_TYPE.LIGHTHOUSE then
        tower.perimeter = hex_ring_map(tower.hex, tower.range)
    end

    register_entity(game_state.towers, tower)
    return tower
end

function build_tower(hex, tower_type)
    local tower = make_and_register_tower(hex, tower_type)
    vplay_sfx(SOUNDS.EXPLOSION4)

    return tower
end

function do_tower_updates()
    for tower_index,tower in pairs(game_state.towers) do
        if tower and tower.update then
            tower.update(tower, tower_index)
        end
    end
end

