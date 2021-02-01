

PROJECTILES = {}

local function update_projectile(projectile, projectile_index)
    projectile.position        = projectile.position + projectile.vector * projectile.velocity
    projectile.node.position2d = projectile.position
    projectile.hex             = pixel_to_hex(projectile.position)

    -- check if we're out of bounds
    if not point_in_rect(projectile.position + WORLDSPACE_COORDINATE_OFFSET, {
        x1 = WIN.left,
        y1 = WIN.bottom,
        x2 = WIN.right,
        y2 = WIN.top
    }) then
        delete_entity(PROJECTILES, projectile_index)
        return true
    end

    -- check if we hit something
    -- get a list of hexes that could have something we could hit on them
    -- right now, it's just the hex we're on and all of its neighbours.
    -- this is done to avoid having to check every mob on screen, though maybe it's not necessary.
    local search_hexes = spiral_map(projectile.hex, 1)
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

    -- hit the mob, delete ourselves, affect the world
    do_hit_mob(closest_mob, projectile.damage, closest_mob_index)
    delete_entity(PROJECTILES, projectile_index)
    vplay_sfx(SOUNDS.HIT1, 0.5)
end

function make_and_register_projectile(hex, vector, velocity, damage, hitbox_radius)
    local projectile = make_basic_entity(hex
                                       , am.line(vector, vector*hitbox_radius, 3, COLORS.CLARET)
                                       , update_projectile)
    projectile.vector        = vector
    projectile.velocity      = velocity
    projectile.damage        = damage
    projectile.hitbox_radius = hitbox_radius

    register_entity(PROJECTILES, projectile)
end

function delete_all_projectiles()
    for projectile_index,projectile in pairs(PROJECTILES) do
        if projectile then delete_entity(PROJECTILES, projectile_index) end
    end
end

function do_projectile_updates()
    for projectile_index,projectile in pairs(PROJECTILES) do
        if projectile and projectile.update then
            projectile.update(projectile, projectile_index)
        end
    end
end

