
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

function get_tower_build_cost(tower_type)
        if tower_type == TOWER_TYPE.REDEYE then return 25
    elseif tower_type == TOWER_TYPE.WALL then   return 5
    elseif tower_type == TOWER_TYPE.MOAT then   return 15
    end
end

function can_afford_tower(money, tower_type)
    local cost = get_tower_build_cost(tower_type)

        if tower_type == TOWER_TYPE.REDEYE then return (money - cost) > 0
    elseif tower_type == TOWER_TYPE.WALL then   return (money - cost) > 0
    elseif tower_type == TOWER_TYPE.MOAT then   return (money - cost) > 0
    end
end

function get_tower_texture(tower_type)
        if tower_type == TOWER_TYPE.REDEYE then return TEX_TOWER_REDEYE
    elseif tower_type == TOWER_TYPE.WALL then   return TEX_TOWER_WALL
    elseif tower_type == TOWER_TYPE.MOAT then   return TEX_TOWER_MOAT
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

function update_wall_texture(hex)
    for _,n in pairs(hex_neighbours(hex)) do
        local tile = HEX_MAP.get(hex.x, hex.y)

    end
end

local function make_tower_sprite(tower_type)
    return pack_texture_into_sprite(get_tower_texture(tower_type), HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)
end

function tower_on_hex(hex)
    return table.find(TOWERS, function(tower)
        return tower.hex == hex
    end)
end

function tower_is_buildable_on(hex, tile, tower_type)
    if hex == HEX_GRID_CENTER then return false end

    local blocked = #mobs_on_hex(hex) ~= 0

    if tower_type == TOWER_TYPE.REDEYE then
        return not blocked and tile.elevation > 0.5

    elseif tower_type == TOWER_TYPE.WALL then
        return not blocked and tile.elevation <= 0.5 and tile.elevation > -0.5

    elseif tower_type == TOWER_TYPE.MOAT then
        return not blocked and tile.elevation <= 0.5 and tile.elevation > -0.5
    end
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
            vplay_sfx(SOUNDS.LASER2)
        end
    end
end

function make_and_register_tower(hex, tower_type)
    local tower = make_basic_entity(
        hex,
        make_tower_sprite(tower_type),
        get_tower_update_function(tower_type)
    )

    tower.range             = 7
    tower.last_shot_time    = tower.TOB
    tower.target_index      = false

    -- make this cell impassable
    HEX_MAP[hex.x][hex.y].elevation = 2
    generate_and_apply_flow_field(HEX_MAP, HEX_GRID_CENTER)

    register_entity(TOWERS, tower)
end

function build_tower(hex, tower_type)
    update_money(-get_tower_build_cost(tower_type))
    make_and_register_tower(hex, tower_type)
    vplay_sfx(SOUNDS.EXPLOSION4)
end

