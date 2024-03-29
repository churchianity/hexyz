
PROJECTILE_TYPE = {
    SHELL = 1,
    LASER = 2,
    BULLET = 3,
}

local PROJECTILE_SPECS = {
    [PROJECTILE_TYPE.SHELL] = {
        velocity = 13,
        damage = 10,
        hitbox_radius = 20
    },
    [PROJECTILE_TYPE.LASER] = {
        velocity = 35,
        damage = 14,
        hitbox_radius = 20
    },
    [PROJECTILE_TYPE.BULLET] = {
        velocity = 25,
        damage = 4,
        hitbox_radius = 10
    }
}

function get_projectile_velocity(projectile_type)
    return PROJECTILE_SPECS[projectile_type].velocity
end
function get_projectile_damage(projectile_type)
    return PROJECTILE_SPECS[projectile_type].damage
end
function get_projectile_hitbox_radius(projectile_type)
    return PROJECTILE_SPECS[projectile_type].hitbox_radius
end
function get_projectile_spec(projectile_type)
    return PROJECTILE_SPECS[projectile_type]
end

local function make_shell_explosion_node(source_position)
    return am.particles2d{
        source_pos = source_position + WORLDSPACE_COORDINATE_OFFSET,
        source_pos_var = vec2(4),
        start_size = 2,
        start_size_var = 1,
        end_size = 0,
        end_size_var = 0,
        angle = 0,
        angle_var = math.pi,
        speed = 85,
        speed_var = 45,
        life = 2,
        life_var = 1,
        start_color = COLORS.VERY_DARK_GRAY,
        start_color_var = vec4(0.2),
        end_color = vec4(0),
        end_color_var = vec4(0.1),
        emission_rate = 0,
        start_particles = 100,
        max_particles = 100,
        gravity = vec2(0, -10),
        warmup_time = 1
    }
    :action(coroutine.create(function(self)
        am.wait(am.delay(3))
    end))
end

local SHELL_GRAVITY = 0.6
local function update_projectile_shell(projectile, projectile_index)
    projectile.position = projectile.position + projectile.vector * projectile.velocity

    if not point_in_rect(projectile.position + WORLDSPACE_COORDINATE_OFFSET, {
        x1 = win.left,
        y1 = win.bottom,
        x2 = win.right,
        y2 = win.top
    }) then
        delete_entity(game_state.projectiles, projectile_index)
        return true
    end

    projectile.node.position2d = projectile.position
    projectile.hex = pixel_to_hex(projectile.position, vec2(HEX_SIZE))

    -- check if we hit something
    -- get a list of hexes that could have something we could hit on them
    -- right now, it's just the hex we're on and all of its neighbours.
    -- this is done to avoid having to check every mob on screen, though maybe it's not necessary.
    local do_explode = false
    local search_hexes = hex_spiral_map(projectile.hex, 1)
    local mobs = {}
    for _,hex in pairs(search_hexes) do
        for index,mob in pairs(mobs_on_hex(hex)) do
            if mob then
                table.insert(mobs, index, mob)

                if circles_intersect(mob.position
                                   , projectile.position
                                   , mob.hurtbox_radius
                                   , projectile.hitbox_radius) then
                    do_explode = true
                    -- we don't break here because if we hit a mob we have to collect all the mobs on the hexes in the search space anyway
                end
            end
        end
    end

    if do_explode then
        for index,mob in pairs(mobs) do
            local damage = (1 / (math.distance(mob.position, projectile.position) / (HEX_PIXEL_WIDTH * 2))) * projectile.damage
            do_hit_mob(mob, damage, index)
        end
        win.scene:append(make_shell_explosion_node(projectile.position))
        delete_entity(game_state.projectiles, projectile_index)
        return true
    end
end

local function update_projectile_laser(projectile, projectile_index)
    projectile.position = projectile.position + projectile.vector * projectile.velocity

    -- check if we're out of bounds
    if not point_in_rect(projectile.position + WORLDSPACE_COORDINATE_OFFSET, {
        x1 = win.left,
        y1 = win.bottom,
        x2 = win.right,
        y2 = win.top
    }) then
        delete_entity(game_state.projectiles, projectile_index)
        return true
    end

    projectile.node.position2d = projectile.position
    projectile.hex = pixel_to_hex(projectile.position, vec2(HEX_SIZE))

    -- check if we hit something
    -- get a list of hexes that could have something we could hit on them
    -- right now, it's just the hex we're on and all of its neighbours.
    -- this is done to avoid having to check every mob on screen, though maybe it's not necessary.
    local search_hexes = hex_spiral_map(projectile.hex, 1)
    local hit_mob_count = 0
    local hit_mobs = {}
    for _,hex in pairs(search_hexes) do

        -- check if there's a mob on the hex
        for mob_index,mob in pairs(mobs_on_hex(hex)) do
            if mob and circles_intersect(mob.position
                                       , projectile.position
                                       , mob.hurtbox_radius
                                       , projectile.hitbox_radius) then
                table.insert(hit_mobs, mob_index, mob)
                hit_mob_count = hit_mob_count + 1
            end
        end
    end

    -- we didn't hit anyone
    if hit_mob_count == 0 then return end

    -- we could have hit multiple, (optionally) find the closest
    local closest_mob_index, closest_mob = next(hit_mobs, nil)
    local closest_d = math.distance(closest_mob.position, projectile.position)
    for _mob_index,mob in pairs(hit_mobs) do
        local d = math.distance(mob.position, projectile.position)
        if d < closest_d then
            closest_mob_index = _mob_index
            closest_mob = mob
            closest_d = d
        end
    end

    -- hit the mob, affect the world
    do_hit_mob(closest_mob, projectile.damage, closest_mob_index)
    vplay_sfx(SOUNDS.HIT1, 0.5)
end

local function update_projectile_bullet(projectile, projectile_index)
    projectile.position = projectile.position + projectile.vector * projectile.velocity

    if not point_in_rect(projectile.position + WORLDSPACE_COORDINATE_OFFSET, {
        x1 = win.left,
        y1 = win.bottom,
        x2 = win.right,
        y2 = win.top
    }) then
        delete_entity(game_state.projectiles, projectile_index)
        return true
    end

    projectile.node.position2d = projectile.position
    projectile.hex = pixel_to_hex(projectile.position, vec2(HEX_SIZE))

    local search_hexes = hex_spiral_map(projectile.hex, 1)
    local hit_mob_count = 0
    local hit_mobs = {}
    for _,hex in pairs(search_hexes) do

        -- check if there's a mob on the hex
        for mob_index,mob in pairs(mobs_on_hex(hex)) do
            if mob and circles_intersect(mob.position
                                       , projectile.position
                                       , mob.hurtbox_radius
                                       , projectile.hitbox_radius) then
                table.insert(hit_mobs, mob_index, mob)
                hit_mob_count = hit_mob_count + 1
            end
        end
    end

    -- we didn't hit anyone
    if hit_mob_count == 0 then return end

    -- we could have hit multiple, (optionally) find the closest
    local closest_mob_index, closest_mob = next(hit_mobs, nil)
    local closest_d = math.distance(closest_mob.position, projectile.position)
    for _mob_index,mob in pairs(hit_mobs) do
        local d = math.distance(mob.position, projectile.position)
        if d < closest_d then
            closest_mob_index = _mob_index
            closest_mob = mob
            closest_d = d
        end
    end

    -- hit the mob, affect the world
    do_hit_mob(closest_mob, projectile.damage, closest_mob_index)
    vplay_sfx(SOUNDS.HIT1, 0.5)
end

function make_projectile_node(projectile_type, vector)
    if projectile_type == PROJECTILE_TYPE.LASER then
        return am.line(vector, vector*get_projectile_hitbox_radius(projectile_type), 3, COLORS.CLARET)

    elseif projectile_type == PROJECTILE_TYPE.BULLET then
        return am.circle(vec2(0), 2, COLORS.VERY_DARK_GRAY)

    elseif projectile_type == PROJECTILE_TYPE.SHELL then
        return am.circle(vec2(0), 3, COLORS.VERY_DARK_GRAY)
    end
end

function get_projectile_update_function(projectile_type)
    if projectile_type == PROJECTILE_TYPE.LASER then
        return update_projectile_laser

    elseif projectile_type == PROJECTILE_TYPE.BULLET then
        return update_projectile_bullet

    elseif projectile_type == PROJECTILE_TYPE.SHELL then
        return update_projectile_shell
    end
end

function make_and_register_projectile(hex, projectile_type, vector)
    local projectile = make_basic_entity(
        hex,
        get_projectile_update_function(projectile_type)
    )

    projectile.type = projectile_type
    projectile.node = am.translate(projectile.position) ^ make_projectile_node(projectile_type, vector)
    projectile.vector = vector

    local spec = get_projectile_spec(projectile_type)
    projectile.velocity = spec.velocity
    projectile.damage = spec.damage
    projectile.hitbox_radius = spec.hitbox_radius

    register_entity(game_state.projectiles, projectile)
    return projectile
end

function projectile_serialize(projectile)
    local serialized = entity_basic_devectored_copy(projectile)
    serialized.vector = { serialized.vector.x, serialized.vector.y }

    return am.to_json(serialized)
end

function projectile_deserialize(json_string)
    local projectile = entity_basic_json_parse(json_string)
    projectile.vector = vec2(projectile.vector[1], projectile.vector[2])

    projectile.update = get_projectile_update_function(projectile.type)
    projectile.node = am.translate(projectile.position)
                      ^ make_projectile_node(projectile.type, projectile.vector)

    return projectile
end

function do_projectile_updates()
    for projectile_index,projectile in pairs(game_state.projectiles) do
        if projectile and projectile.update then
            projectile.update(projectile, projectile_index)
        end
    end
end

