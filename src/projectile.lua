

function make_and_register_projectile(hex, vector, velocity, damage, hitbox_radius)
    local projectile = make_and_register_entity(
        -- type
        ENTITY_TYPE.PROJECTILE,

        hex,

        -- node
        am.circle(vec2(0), hitbox_radius - 1, COLORS.CLARET),

        -- update function
        function(_projectile, _projectile_index)
            _projectile.position        = _projectile.position + vector * velocity
            _projectile.node.position2d = _projectile.position
            _projectile.hex             = pixel_to_hex(_projectile.position)

            local mob_index,mob = mob_on_hex(_projectile.hex)
            if mob and circles_intersect(mob.position
                                       , _projectile.position
                                       , mob.hurtbox_radius
                                       , _projectile.hitbox_radius) then

                do_hit_mob(mob, _projectile.damage, mob_index)
                delete_entity(_projectile_index)
                WORLD:action(vplay_sound(SOUNDS.HIT1))

            elseif not point_in_rect(_projectile.position + WORLDSPACE_COORDINATE_OFFSET, {
                x1 = WIN.left,
                y1 = WIN.bottom,
                x2 = WIN.right,
                y2 = WIN.top
            }) then
                delete_entity(_projectile_index)
            end
        end
    )

    projectile.vector        = vector
    projectile.velocity      = velocity
    projectile.damage        = damage
    projectile.hitbox_radius = hitbox_radius
end

