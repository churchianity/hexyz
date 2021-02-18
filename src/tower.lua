

TOWERS = {}

TOWER_TYPE = {
    WALL       = 1,
    HOWITZER   = 2,
    --         = 3,
    REDEYE     = 3,
    --         = 5,
    MOAT       = 4,
    --         = 7,
    RADAR      = 5,
    --         = 9,
    LIGHTHOUSE = 6
}

TOWER_SPECS = {
    [TOWER_TYPE.WALL] = {
        name = "Wall",
        placement_rules_text = "Place on Ground",
        short_description = "Restricts movement",
        texture = TEXTURES.TOWER_WALL,
        icon_texture = TEXTURES.TOWER_WALL_ICON,
        cost = 10,
        range = 0,
        fire_rate = 2,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.HOWITZER] = {
        name = "Howitzer",
        placement_rules_text = "Place on non-Water, non-Mountain or on Walls",
        short_description = "Fires artillery. Range increases with elevation of terrain underneath.",
        texture = TEXTURES.TOWER_HOWITZER,
        icon_texture = TEXTURES.TOWER_HOWITZER_ICON,
        cost = 20,
        range = 10,
        fire_rate = 4,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.REDEYE] = {
        name = "Redeye",
        placement_rules_text = "Place on Mountains or on Walls",
        short_description = "Long-range, single-target laser tower",
        texture = TEXTURES.TOWER_REDEYE,
        icon_texture = TEXTURES.TOWER_REDEYE_ICON,
        cost = 20,
        range = 12,
        fire_rate = 1,
        size = 0,
        height = 1,
    },
    [TOWER_TYPE.MOAT] = {
        name = "Moat",
        placement_rules_text = "Place on Ground",
        short_description = "Restricts movement",
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
        placement_rules_text = "Place on any non-Water",
        short_description = "Provides information about incoming waves.",
        texture = TEXTURES.TOWER_RADAR,
        icon_texture = TEXTURES.TOWER_RADAR_ICON,
        cost = 20,
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
        cost = 20,
        range = 8,
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

local HEX_FLOWER_DIMENSIONS = vec2(115, 125)
local function make_tower_node(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return make_tower_sprite(tower_type)

    elseif tower_type == TOWER_TYPE.HOWITZER then
        return am.group{
            pack_texture_into_sprite(TEXTURES.HEX_FLOWER, HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT),
            am.rotate(state.time or 0) ^ am.group{
                pack_texture_into_sprite(TEXTURES.CANNON1, 50, 50)
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
        return am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY, 6)

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

local function get_tower_update_function(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return update_tower_redeye

    elseif tower_type == TOWER_TYPE.HOWITZER then
        return update_tower_howitzer

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        return update_tower_lighthouse
    end
end

function towers_on_hex(hex)
    local t = {}
    for tower_index,tower in pairs(TOWERS) do
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
    return table.find(TOWERS, function(tower)
        for _,h in pairs(tower.hexes) do
            if h == hex then return true end
        end
    end)
end

function tower_type_is_buildable_on(hex, tile, tower_type)
    if not tower_type then return false end

    -- @TODO remove this shit
    if hex == HEX_GRID_CENTER then return false end

    local blocking_towers = {}
    local blocking_mobs = {}
    local has_water = false
    local has_mountain = false
    local has_ground = false

    for _,h in pairs(spiral_map(hex, get_tower_size(tower_type))) do
        table.merge(blocking_towers, towers_on_hex(h))
        table.merge(blocking_mobs, mobs_on_hex(h))

        local tile = state.map.get(h.x, h.y)
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

    if tower_type == TOWER_TYPE.HOWITZER then
        if not mobs_blocking and towers_blocking then
            -- you can build howitzers on top of walls.
            blocked = false
            for _,tower in pairs(blocking_towers) do
                if tower.type ~= TOWER_TYPE.WALL then
                    blocked = true
                    break
                end
            end
        end
        return not (blocked or has_water or has_mountain)

    elseif tower_type == TOWER_TYPE.REDEYE then
        if not mobs_blocking and towers_blocking then
            -- you can build redeyes on top of walls
            blocked = false
            for _,tower in pairs(blocking_towers) do
                if tower.type ~= TOWER_TYPE.WALL then
                    blocked = true
                    break
                end
            end
        end
        return not blocked
               and not has_water
               and not has_ground
               and has_mountain

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        local has_water_neighbour = false
        for _,h in pairs(hex_neighbours(hex)) do
            local tile = state.map.get(h.x, h.y)

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

function update_tower_redeye(tower, tower_index)
    if not tower.target_index then
        for index,mob in pairs(MOBS) do
            if mob then
                local d = math.distance(mob.hex, tower.hex)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end
    else
        if MOBS[tower.target_index] == false then
            tower.target_index = false

        elseif (state.time - tower.last_shot_time) > tower.fire_rate then
            local mob = MOBS[tower.target_index]

            make_and_register_projectile(
                tower.hex,
                PROJECTILE_TYPE.LASER,
                math.normalize(mob.position - tower.position)
            )

            tower.last_shot_time = state.time
            vplay_sfx(SOUNDS.LASER2)
        end
    end
end

function update_tower_howitzer(tower, tower_index)
    if not tower.target_index then
        -- we don't have a target
        for index,mob in pairs(MOBS) do
            if mob then
                local d = math.distance(mob.hex, tower.hex)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end
        tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
    else
        -- we should have a target
        if MOBS[tower.target_index] == false then
            -- the target we have was invalidated
            tower.target_index = false

        else
            -- the target we have is valid
            local mob = MOBS[tower.target_index]
            local vector = math.normalize(mob.position - tower.position)

            if (state.time - tower.last_shot_time) > tower.fire_rate then
                local projectile = make_and_register_projectile(
                    tower.hex,
                    PROJECTILE_TYPE.SHELL,
                    vector
                )

                -- @HACK, the projectile will explode if it encounters something taller than it,
                -- but the tower it spawns on quickly becomes taller than it, so we just pad it
                -- if it's not enough the shell explodes before it leaves its spawning hex
                projectile.props.z = tower.props.z + 0.1

                tower.last_shot_time = state.time
                play_sfx(SOUNDS.EXPLOSION2)
            end

            local theta = math.rad(90) - math.atan((tower.position.y - mob.position.y)/(tower.position.x - mob.position.x))
            local diff = tower.node("rotate").angle - theta

            tower.node("rotate").angle = -theta + math.pi/2
        end
    end
end

function update_tower_lighthouse(tower, tower_index)
    -- check if there's a mob on a hex in our perimeter
    for _,h in pairs(tower.perimeter) do
        local mobs = mobs_on_hex(h)

        for _,m in pairs(mobs) do
            if not m.path then
                -- @TODO only attract the mob if its frame target (direction vector)
                -- is within some angle range...? if the mob is heading directly away from the tower, then
                -- the lighthouse shouldn't do much

                local path, made_it = Astar(state.map, tower.hex, m.hex, grid_heuristic, grid_cost)

                if made_it then
                    m.path = path

                    --[[
                    local area = spiral_map(tower.hex, tower.range)
                    for _,h in pairs(area) do
                        local node = state.map[h.x][h.y].node"circle"
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

function make_and_register_tower(hex, tower_type)
    local tower = make_basic_entity(
        hex,
        make_tower_node(tower_type),
        get_tower_update_function(tower_type)
    )

    tower.type = tower_type

    local spec = get_tower_spec(tower_type)
    tower.cost = spec.cost
    tower.range = spec.range
    tower.fire_rate = spec.fire_rate
    tower.last_shot_time = -spec.fire_rate
    tower.size = spec.size
    if tower.size == 0 then
        tower.hexes = { tower.hex }
    else
        tower.hexes = spiral_map(tower.hex, tower.size)
    end
    tower.height = spec.height

    for _,h in pairs(tower.hexes) do
        local tile = state.map.get(h.x, h.y)
        tile.elevation = tile.elevation + tower.height
    end

    if tower.type == TOWER_TYPE.HOWITZER then
        tower.props.z = tower.height
    end

    register_entity(TOWERS, tower)
    return tower
end

function build_tower(hex, tower_type)
    local tower = make_and_register_tower(hex, tower_type)
    vplay_sfx(SOUNDS.EXPLOSION4)

    return tower
end

function delete_all_towers()
    for tower_index,tower in pairs(TOWERS) do
        if tower then delete_entity(TOWERS, tower_index) end
    end
end

function do_tower_updates()
    for tower_index,tower in pairs(TOWERS) do
        if tower and tower.update then
            tower.update(tower, tower_index)
        end
    end
end

