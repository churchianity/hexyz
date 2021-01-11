
--[[
tower(entity) structure:
{
    -- @NOTE these should probably be wrapped in a 'weapon' struct or something, so towers can have multiple weapons
    range           - number    - distance it can shoot
    last_shot_time  - number    - timestamp (seconds) of last time it shot
    target_index    - number    - index of entity it is currently shooting
}
--]]

TOWER_TYPE = {
    REDEYE = 1,
    WALL   = 2,
    MOAT   = 3,
}

function get_tower_texture(tower_type)
        if tower_type == TOWER_TYPE.REDEYE then return TEX_TOWER2
    elseif tower_type == TOWER_TYPE.WALL then   return TEX_WALL_CLOSED
    elseif tower_type == TOWER_TYPE.MOAT then   return TEX_MOAT1
    end
end

function tower_type_tostring(tower_type)
        if tower_type == TOWER_TYPE.REDEYE then return "Redeye Tower"
    elseif tower_type == TOWER_TYPE.WALL then   return "Wall"
    elseif tower_type == TOWER_TYPE.MOAT then   return "Moat"
    end
end

local function get_tower_update_function(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return update_tower_redeye
    end
end

local function make_tower_sprite(tower_type)
    local texture = get_tower_texture(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return pack_texture_into_sprite(texture, HEX_PIXEL_SIZE.x, HEX_PIXEL_SIZE.y)

    elseif tower_type == TOWER_TYPE.WALL then
        --return pack_texture_into_sprite(TEX_WALL_CLOSED, HEX_PIXEL_SIZE.x, HEX_PIXEL_SIZE.y)
        return am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY, 6)

    elseif tower_type == TOWER_TYPE.MOAT then
        --return pack_texture_into_sprite(TEX_MOAT1, HEX_PIXEL_SIZE.x, HEX_PIXEL_SIZE.y)
        return am.circle(vec2(0), HEX_SIZE, COLORS.YALE_BLUE, 6)
    end
end

function is_buildable(hex, tile, tower)
    local blocked = #mobs_on_hex(hex) ~= 0
    return not blocked and tile.elevation <= 0.5 and tile.elevation > -0.5
end

function update_tower_redeye(tower, tower_index)
    if not tower.target_index then
        for index,mob in pairs(MOBS) do
            if mob then
                local d = math.distance(mob.position, tower.position) / (HEX_SIZE * 2)
                if d <= tower.range then
                    tower.target_index = index
                    break
                end
            end
        end
    else
        if MOBS[tower.target_index] == false then
            tower.target_index = false

        elseif (TIME - tower.last_shot_time) > 1 then
            local mob = MOBS[tower.target_index]

            make_and_register_projectile(
                tower.hex,
                math.normalize(hex_to_pixel(mob.hex) - tower.position),
                15,
                5,
                10
            )

            tower.last_shot_time = TIME
            tower.node:action(vplay_sound(SOUNDS.LASER2))
        end
    end
end

function make_and_register_tower(hex, tower_type)
    local tower = make_basic_entity(
        hex,
        make_tower_sprite(tower_type),
        get_tower_update_function(tower_type)
    )

    tower.range             = 10
    tower.last_shot_time    = tower.TOB
    tower.target_index      = false

    -- make this cell impassable
    HEX_MAP[hex.x][hex.y].elevation = 2

    register_entity(TOWERS, tower)
end

function build_tower(hex, tower_type)
    make_and_register_tower(hex, tower_type)
    WIN.scene:action(am.play(am.sfxr_synth(SOUNDS.EXPLOSION4)))
end

