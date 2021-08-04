
TOWER_TYPE = {
    WALL       = 1,
    GATTLER    = 2,
    HOWITZER   = 3,
    REDEYE     = 4,
    --         = 5,
    MOAT       = 5,
    --         = 7,
    RADAR      = 6,
    --         = 9,
    LIGHTHOUSE = 7
}

local TOWER_SPECS = {
    [TOWER_TYPE.WALL] = {
        name = "Wall",
        placement_rules_text = "Place on Ground",
        short_description = "Restricts movement, similar to a mountain.",
        texture = TEXTURES.TOWER_WALL,
        icon_texture = TEXTURES.TOWER_WALL_ICON,
        cost = 10,
        range = 0,
        fire_rate = 2,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.GATTLER] = {
        name = "Gattler",
        placement_rules_text = "Place on Ground",
        short_description = "Short-range, fast-fire rate single-target tower.",
        texture = TEXTURES.TOWER_GATTLER,
        icon_texture = TEXTURES.TOWER_GATTLER_ICON,
        cost = 20,
        range = 4,
        fire_rate = 0.5,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.HOWITZER] = {
        name = "Howitzer",
        placement_rules_text = "Place on Ground, with a 1 space gap between other towers and mountains - walls/moats don't count.",
        short_description = "Medium-range, medium fire-rate area of effect artillery tower.",
        texture = TEXTURES.TOWER_HOWITZER,
        icon_texture = TEXTURES.TOWER_HOWITZER_ICON,
        cost = 50,
        range = 6,
        fire_rate = 4,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.REDEYE] = {
        name = "Redeye",
        placement_rules_text = "Place on Mountains.",
        short_description = "Long-range, penetrating high-velocity laser tower.",
        texture = TEXTURES.TOWER_REDEYE,
        icon_texture = TEXTURES.TOWER_REDEYE_ICON,
        cost = 75,
        range = 9,
        fire_rate = 3,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.MOAT] = {
        name = "Moat",
        placement_rules_text = "Place on Ground",
        short_description = "Restricts movement, similar to water.",
        texture = TEXTURES.TOWER_MOAT,
        icon_texture = TEXTURES.TOWER_MOAT_ICON,
        cost = 10,
        range = 0,
        fire_rate = 2,
        size = 0,
        height = -1,
    },
    [TOWER_TYPE.RADAR] = {
        name = "Radar",
        placement_rules_text = "n/a",
        short_description = "Doesn't do anything right now :(",
        texture = TEXTURES.TOWER_RADAR,
        icon_texture = TEXTURES.TOWER_RADAR_ICON,
        cost = 100,
        range = 0,
        fire_rate = 1,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.LIGHTHOUSE] = {
        name = "Lighthouse",
        placement_rules_text = "Place on Ground, adjacent to Water or Moats",
        short_description = "Attracts nearby mobs; temporarily redirects their path",
        texture = TEXTURES.TOWER_LIGHTHOUSE,
        icon_texture = TEXTURES.TOWER_LIGHTHOUSE_ICON,
        cost = 150,
        range = 7,
        fire_rate = 1,
        size = 0,
        height = 1,
    },
}

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

local function make_tower_sprite(tower_type)
    return pack_texture_into_sprite(get_tower_texture(tower_type), HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)
end

function make_tower_node(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return make_tower_sprite(tower_type)

    elseif tower_type == TOWER_TYPE.GATTLER then
        return am.group{
                am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 5),
                am.rotate(game_state.time or 0)
                ^ pack_texture_into_sprite(TEXTURES.TOWER_HOWITZER, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2, COLORS.GREEN_YELLOW)
           }

    elseif tower_type == TOWER_TYPE.HOWITZER then
        return am.group{
            am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 6),
            am.rotate(game_state.time or 0) ^ am.group{
                pack_texture_into_sprite(TEXTURES.TOWER_HOWITZER, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2) -- CHONK
            }
        }
    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
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
    elseif tower_type == TOWER_TYPE.WALL then
        return am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY{a=0.75}, 6)

    elseif tower_type == TOWER_TYPE.MOAT then
        return am.circle(vec2(0), HEX_SIZE, COLORS.WATER{a=1}, 6)

    elseif tower_type == TOWER_TYPE.RADAR then
        return make_tower_sprite(tower_type)
    end
end

do
    local tower_cursors = {}
    for _,i in pairs(TOWER_TYPE) do
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
            make_hex_cursor(get_tower_range(i), vec4(0), coroutine_),
            tower_sprite
        }
    end

    function get_tower_cursor(tower_type)
        return tower_cursors[tower_type]
    end
end

local function update_tower_redeye(tower, tower_index)
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
    else
        if not game_state.mobs[tower.target_index] then
            tower.target_index = false

        elseif (game_state.time - tower.last_shot_time) > tower.fire_rate then
            local mob = game_state.mobs[tower.target_index]

            make_and_register_projectile(
                tower.hex,
                PROJECTILE_TYPE.LASER,
                math.normalize(mob.position - tower.position)
            )

            tower.last_shot_time = game_state.time
            vplay_sfx(SOUNDS.LASER2)
        end
    end
end

local function update_tower_gattler(tower, tower_index)
    if not tower.target_index then
        -- we should try and acquire a target
        for index,mob in pairs(game_state.mobs) do
            if mob then
                local d = math.distance(mob.hex, tower.hex)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end

        -- passive animation
        tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
    else
        -- should have a target, so we should try and shoot it
        if not game_state.mobs[tower.target_index] then
            -- the target we have was invalidated
            tower.target_index = false

        else
            -- the target we have is valid
            local mob = game_state.mobs[tower.target_index]
            local vector = math.normalize(mob.position - tower.position)

            if (game_state.time - tower.last_shot_time) > tower.fire_rate then
                local projectile = make_and_register_projectile(
                    tower.hex,
                    PROJECTILE_TYPE.BULLET,
                    vector
                )

                tower.last_shot_time = game_state.time
                play_sfx(SOUNDS.HIT1)
            end

            -- point the cannon at the dude
            local theta = math.rad(90) - math.atan((tower.position.y - mob.position.y)/(tower.position.x - mob.position.x))
            local diff = tower.node("rotate").angle - theta

            tower.node("rotate").angle = -theta + math.pi/2
        end
    end
end

local function update_tower_howitzer(tower, tower_index)
    if not tower.target_index then
        -- we don't have a target
        for index,mob in pairs(game_state.mobs) do
            if mob then
                local d = math.distance(mob.hex, tower.hex)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end

        -- passive animation
        tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
    else
        -- we should have a target
        -- @NOTE don't compare to false, empty indexes appear on game reload
        if not game_state.mobs[tower.target_index] then
            -- the target we have was invalidated
            tower.target_index = false

        else
            -- the target we have is valid
            local mob = game_state.mobs[tower.target_index]
            local vector = math.normalize(mob.position - tower.position)

            if (game_state.time - tower.last_shot_time) > tower.fire_rate then
                local projectile = make_and_register_projectile(
                    tower.hex,
                    PROJECTILE_TYPE.SHELL,
                    vector
                )

                -- @HACK, the projectile will explode if it encounters something taller than it,
                -- but the tower it spawns on quickly becomes taller than it, so we just pad it
                -- if it's not enough the shell explodes before it leaves its spawning hex
                projectile.props.z = tower.props.z + 0.1

                tower.last_shot_time = game_state.time
                play_sfx(SOUNDS.EXPLOSION2)
            end

            -- point the cannon at the dude
            local theta = math.rad(90) - math.atan((tower.position.y - mob.position.y)/(tower.position.x - mob.position.x))
            local diff = tower.node("rotate").angle - theta

            tower.node("rotate").angle = -theta + math.pi/2
        end
    end
end

local function update_tower_lighthouse(tower, tower_index)
    -- check if there's a mob on a hex in our perimeter
    for _,h in pairs(tower.perimeter) do
        local mobs = mobs_on_hex(h)

        for _,m in pairs(mobs) do
            if not m.path and not m.seen_lighthouse then
                -- @TODO only attract the mob if its frame target (direction vector)
                -- is within some angle range...? if the mob is heading directly away from the tower, then
                -- the lighthouse shouldn't do much

                local path, made_it = hex_Astar(game_state.map, tower.hex, m.hex, grid_neighbours, grid_cost, grid_heuristic)

                if made_it then
                    m.path = path
                    m.seen_lighthouse = true -- right now mobs don't care about lighthouses if they've already seen one.

                    --[[
                    local area = spiral_map(tower.hex, tower.range)
                    for _,h in pairs(area) do
                        local node = game_state.map[h.x][h.y].node"circle"
                        local initial_color = node.color

                        local d = math.distance(h, tower.hex)
                        local target_color = COLORS.SUNRAY{ a = 1/(d/tower.range) + 0.9 }
                        node:late_action(am.series{
                            am.tween(node, 0.3, { color = target_color }),
                            am.tween(node, 0.3, { color = initial_color })
                        })
                    end
                    ]]
                end
            end
        end
    end
end

local function get_tower_update_function(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return update_tower_redeye

    elseif tower_type == TOWER_TYPE.GATTLER then
        return update_tower_gattler

    elseif tower_type == TOWER_TYPE.HOWITZER then
        return update_tower_howitzer

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        return update_tower_lighthouse
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

