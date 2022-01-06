
function default_tower_placement_f(blocked, has_water, has_mountain, has_ground, hex)
    return not (blocked or has_water or has_mountain)
end

function default_weapon_target_acquisition_f(tower, tower_index)
    for index,mob in pairs(game_state.mobs) do
        if mob then
            local d = math.distance(mob.hex, tower.hex)
            if d <= tower.range then
                tower.target_index = index
                break
            end
        end
    end

end

function default_tower_target_acquisition_f(tower, tower_index)
    -- first, find out if a tower even *should*, acquire a target.
    -- a tower should try and acquire a target if atleast one of its weapons that could be shooting, isn't


    if not tower.target_index then
        for index,mob in pairs(game_state.mobs) do
            if mob then
                local d = math.distance(mob.hex, tower.hex)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end
    end
end

function default_tower_update_f(tower, tower_index)
end

-- load tower spec file
TOWER_SPECS = {}
TOWER_TYPE = {}

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

function resolve_tower_specs(spec_file_path)
    local spec_file = am.load_script(spec_file_path)
    local error_message
    if spec_file then
        local status, tower_specs = pcall(spec_file)

        if status then
            -- lua managed to run the file without syntax/runtime errors
            -- it's not garunteed to be what we want yet. check:
            local type_ = type(tower_specs)
            if type_ ~= "table" then
                error_message = "tower spec file should return a table, but we got " .. type_
            end

            -- if we're here, then we're going to assume the spec file is valid, no matter how weird it is
            -- last thing to do before returning is fill in missing default values
            for i,tower_spec in pairs(tower_specs) do

                if not tower_spec.size then
                    tower_spec.size = 1
                end
                if not tower_spec.height then
                    tower_spec.height = 1
                end

                if not tower_spec.update_f then
                    tower_spec.update_f = default_tower_update_f
                end

                if not tower_spec.weapons then
                    tower_spec.weapons = {}
                end
                for i,w in pairs(tower_spec.weapons) do
                    if not w.min_range then
                        w.min_range = 0
                    end
                    if not w.target_acquisition_f then
                        w.target_acquisition_f = default_weapon_target_acquisition_f
                    end
                end

                if not tower_spec.placement_f then
                    tower_spec.placement_f = default_tower_placement_f
                end

                -- resolve a tower's visual range - if not provided we should use the largest range among weapons it has
                if not tower_spec.visual_range then
                    local largest_range = 0
                    for i,w in pairs(tower_spec.weapons) do
                        if w.range > largest_range then
                            largest_range = w.range
                        end
                    end
                    tower_spec.visual_range = largest_range
                end
                -- do the same for the minimum visual range
                if not tower_spec.min_visual_range then
                    local largest_minimum_range = 0
                    for i,w in pairs(tower_spec.weapons) do
                        if w.min_range > largest_minimum_range then
                            largest_minimum_range = w.min_range
                        end
                    end
                    tower_spec.min_visual_range = largest_minimum_range
                end
            end

            TOWER_SPECS = tower_specs
            for i,t in pairs(TOWER_SPECS) do
                TOWER_TYPE[t.id] = i
            end
            build_tower_cursors()
            return
        else
            -- runtime error - including syntax errors
            error_message = result
        end
    else
        -- filesystem/permissions related error - couldn't load the file
        error_message = "couldn't load the file"
    end

    log(error_message)
    -- @TODO no matter what fucked up, we should load defaults
    TOWER_SPECS = {}
    build_tower_cursors()
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

function build_tower_cursors()
    local tower_cursors = {}
    for i,tower_spec in pairs(TOWER_SPECS) do
        local tower_sprite = make_tower_node(i)
        tower_sprite.color = COLORS.TRANSPARENT3

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
            make_hex_cursor_node(tower_spec.visual_range, vec4(0), coroutine_, tower_spec.min_visual_range),
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

    -- you can't build anything in the center, probably ever?
    if hex == HEX_GRID_CENTER then return false end

    local blocking_towers = {}
    local blocking_mobs = {}
    local has_water = false
    local has_mountain = false
    local has_ground = false
    local tower_spec = get_tower_spec(tower_type)

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

    return tower_spec.placement_f(blocked, has_water, has_mountain, has_ground, hex)
end

function make_and_register_tower(hex, tower_type)
    local spec = get_tower_spec(tower_type)
    local tower = make_basic_entity(
        hex,
        spec.update_f
    )

    table.merge(tower, spec)

    tower.type = tower_type
    tower.node = am.translate(tower.position) ^ make_tower_node(tower_type)

    for i,w in pairs(tower.weapons) do
        w.last_shot_time = -tower.weapons[i].fire_rate -- lets the tower fire immediately upon being placed
    end

    if tower.size == 1 then
        tower.hexes = { tower.hex }
    else
        tower.hexes = hex_spiral_map(tower.hex, tower.size - 1)
    end

    -- should we be permuting the map here?
    for _,h in pairs(tower.hexes) do
        local tile = hex_map_get(game_state.map, h.x, h.y)
        tile.elevation = tile.elevation + tower.height
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

