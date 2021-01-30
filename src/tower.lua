

TOWER_TYPE = {
    REDEYE     = 1,
    LIGHTHOUSE = 2,
    WALL       = 3,
    MOAT       = 4,
}

TOWER_SPECS = {
    [TOWER_TYPE.REDEYE] = {
        name = "Redeye",
        placement_rules_text = "Place on mountains or on Walls",
        short_description = "Long range laser tower",
        texture = TEXTURES.TOWER_REDEYE,
        base_cost = 25,
    },
    [TOWER_TYPE.LIGHTHOUSE] = {
        name = "Lighthouse",
        placement_rules_text = "Place next to - but not on - water or moats",
        short_description = "Attracts and distracts mobs",
        texture = TEXTURES.TOWER_LIGHTHOUSE,
        base_cost = 25
    },
    [TOWER_TYPE.WALL] = {
        name = "Wall",
        placement_rules_text = "Place on grass or dirt",
        short_description = "Restricts movement",
        texture = TEXTURES.TOWER_WALL,
        base_cost = 5,
    },
    [TOWER_TYPE.MOAT] = {
        name = "Moat",
        placement_rules_text = "Place on grass or dirt",
        short_description = "Restricts movement",
        texture = TEXTURES.TOWER_MOAT,
        base_cost = 5,
    }
}

function get_tower_name(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].name
end
function get_tower_placement_rules_text(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].placement_rules_text
end
function get_tower_short_description(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].short_description
end
function get_tower_texture(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].texture
end
function get_tower_base_cost(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].base_cost
end

function can_afford_tower(money, tower_type)
    local cost = get_tower_base_cost(tower_type)
    return (money - cost) >= 0
end

local function get_tower_update_function(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return update_tower_redeye

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        return update_tower_lighthouse
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

    local blocked = tower_on_hex(hex) or #mobs_on_hex(hex) ~= 0

    if tower_type == TOWER_TYPE.REDEYE then
        return not blocked and tile.elevation > 0.5

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        local has_water_neighbour = false
        for _,h in pairs(hex_neighbours(hex)) do
            local tile = HEX_MAP.get(h.x, h.y)

            if tile and tile.elevation < -0.5 then
                has_water_neighbour = true
                break
            end
        end
        return not blocked and tile.elevation <= 0.5 and tile.elevation > -0.5 and has_water_neighbour

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

function update_tower_lighthouse(tower, tower_index)
    -- check if there's a mob on a hex in our perimeter
    for _,h in pairs(tower.perimeter) do
        local mobs = mobs_on_hex(h)

        for _,m in pairs(mobs) do
            if not m.path then
                local path, made_it = Astar(HEX_MAP, tower.hex, m.hex, grid_heuristic, grid_cost)

                if made_it then
                    m.path = path
                end
            end
        end
    end
end

function make_and_register_tower(hex, tower_type)
    local tower = make_basic_entity(
        hex,
        make_tower_sprite(tower_type),
        get_tower_update_function(tower_type)
    )

    tower.type = tower_type
    if tower_type == TOWER_TYPE.REDEYE then
        tower.range          = 7
        tower.last_shot_time = tower.TOB
        tower.target_index   = false

        HEX_MAP[hex.x][hex.y].elevation = 2

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        tower.range = 4
        tower.perimeter = ring_map(tower.hex, tower.range)

    elseif tower_type == TOWER_TYPE.WALL then
        HEX_MAP[hex.x][hex.y].elevation = 1

    elseif tower_type == TOWER_TYPE.MOAT then
        HEX_MAP[hex.x][hex.y].elevation = 0

    end

    generate_and_apply_flow_field(HEX_MAP, HEX_GRID_CENTER, WORLD)

    register_entity(TOWERS, tower)
end

function build_tower(hex, tower_type)
    update_money(-get_tower_base_cost(tower_type))
    make_and_register_tower(hex, tower_type)
    vplay_sfx(SOUNDS.EXPLOSION4)
end

