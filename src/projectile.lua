


function make_and_register_projectile(hex, vector, velocity)
    local projectile = make_and_register_entity(
        -- type
        ENTITY_TYPE.PROJECTILE,

        hex,

        -- node
        am.line(vector, vector * 4, 2, COLORS.CLARET),

        function(_projectile, _projectile_index)
            _projectile.position        = _projectile.position + vector * velocity
            _projectile.node.position2d = _projectile.position
            _projectile.hex             = pixel_to_hex(_projectile.position)

            local mob_index,mob = mob_on_hex(_projectile.hex)
            if mob and (math.distance(mob.position, _projectile.position) > _projectile.hitbox_radius) then
                do_hit_mob(mob, _projectile.damage, mob_index)
                delete_entity(_projectile_index)
                WIN.scene"world":action(am.play(am.sfxr_synth(SOUNDS.HIT1)))
            end
        end
    )

    projectile.vector = vector
    projectile.velocity = velocity
    projectile.damage = 5
    projectile.hitbox_radius = 10
end

