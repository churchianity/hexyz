

function is_buildable(hex, tile, tower)
    local blocked = mob_on_hex(hex)
    return not blocked and is_passable(tile)
end

function make_and_register_tower(hex)
    local tower = make_and_register_entity(
        -- type
        ENTITY_TYPE.TOWER,

        -- spawning hex
        hex,

        -- node
        pack_texture_into_sprite(TEX_TOWER2, 45, 34),

        -- update function
        function(_tower, _tower_index)
            if not _tower.target_index then
                for index,entity in pairs(ENTITIES) do
                    if entity and entity.type == ENTITY_TYPE.MOB then
                        local d = math.distance(entity.hex, _tower.hex)
                        if d <= _tower.range then
                            _tower.target_index = index
                            break
                        end
                    end
                end
            else
                if ENTITIES[_tower.target_index] == nil then
                    _tower.target_index = false

                elseif (TIME - _tower.last_shot_time) > 1 then
                    local entity = ENTITIES[_tower.target_index]

                    make_and_register_projectile(
                        _tower.hex,
                        math.normalize(hex_to_pixel(entity.hex) - _tower.position),
                        15,
                        5,
                        4
                    )

                    _tower.last_shot_time = TIME
                    _tower.node:action(vplay_sound(SOUNDS.LASER2))
                end
            end
        end
    )

    tower.range             = 10
    tower.last_shot_time    = tower.TOB
    tower.target_index      = false

    -- make this cell impassable
    HEX_MAP[hex.x][hex.y].elevation = 2
    check_for_broken_mob_pathing(hex)
end

