

TOWERS = {}

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
        icon_texture = TEXTURES.TOWER_REDEYE_ICON,
        base_cost = 25,
    },
    [TOWER_TYPE.LIGHTHOUSE] = {
        name = "Lighthouse",
        placement_rules_text = "Place next to - but not on - water or moats",
        short_description = "Attracts and distracts mobs",
        texture = TEXTURES.TOWER_LIGHTHOUSE,
        icon_texture = TEXTURES.TOWER_LIGHTHOUSE_ICON,
        base_cost = 25
    },
    [TOWER_TYPE.WALL] = {
        name = "Wall",
        placement_rules_text = "Place on grass or dirt",
        short_description = "Restricts movement",
        texture = TEXTURES.TOWER_WALL,
        icon_texture = TEXTURES.TOWER_WALL_ICON,
        base_cost = 5,
    },
    [TOWER_TYPE.MOAT] = {
        name = "Moat",
        placement_rules_text = "Place on grass or dirt",
        short_description = "Restricts movement",
        texture = TEXTURES.TOWER_MOAT,
        icon_texture = TEXTURES.TOWER_MOAT_ICON,
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
function get_tower_icon_texture(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].icon_texture
end
function get_tower_base_cost(tower_type)
    return TOWER_SPECS[tower_type] and TOWER_SPECS[tower_type].base_cost
end

local function make_tower_sprite(tower_type)
    return pack_texture_into_sprite(get_tower_texture(tower_type), HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)
end

do
    local tower_cursors = {}
    for _,i in pairs(TOWER_TYPE) do
        tower_cursors[i] = make_tower_sprite(i)
        tower_cursors[i].color = COLORS.TRANSPARENT
    end

    function get_tower_cursor(tower_type)
        return tower_cursors[tower_type]
    end
end

local function make_tower_node(tower_type)
    if tower_type == TOWER_TYPE.REDEYE then
        return make_tower_sprite(tower_type)

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        return am.group(
            make_tower_sprite(tower_type)
        )
    elseif tower_type == TOWER_TYPE.WALL then
        return am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY, 6)

    elseif tower_type == TOWER_TYPE.MOAT then
        return am.circle(vec2(0), HEX_SIZE, (COLORS.WATER){a=1}, 6)

    end
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


function towers_on_hex(hex)
    local t = {}
    for tower_index,tower in pairs(TOWERS) do
        if tower and tower.hex == hex then
            table.insert(t, tower_index, tower)
        end
    end
    return t
end


function tower_on_hex(hex)
    return table.find(TOWERS, function(tower)
        return tower.hex == hex
    end)
end

function tower_is_buildable_on(hex, tile, tower_type)
    if hex == HEX_GRID_CENTER then return false end

    local blocking_towers       = towers_on_hex(hex)
    local blocking_mobs         = mobs_on_hex(hex)

    local towers_blocking       = #blocking_towers ~= 0
    local mobs_blocking         = #blocking_mobs ~= 0

    local blocked = mobs_blocking or towers_blocking

    if tower_type == TOWER_TYPE.REDEYE then
        if not mobs_blocking and towers_blocking then
            blocked = false
            for _,tower in pairs(TOWERS) do
                if tower.type ~= TOWER_TYPE.WALL then
                    blocked = true
                    break
                end
            end
        end
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
        return not blocked and tile_is_medium_elevation(tile) and has_water_neighbour

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

                    local area = spiral_map(tower.hex, tower.range)
                    for _,h in pairs(area) do
                        local node = HEX_MAP[h.x][h.y].node"circle"
                        local initial_color = node.color

                        local d = math.distance(h, tower.hex)
                        local target_color = COLORS.SUNRAY{ a = 1/(d/tower.range) }
                        node:late_action(am.series{
                            am.tween(node, 0.3, { color = target_color }),
                            am.tween(node, 0.3, { color = initial_color })
                        })
                    end
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

    local need_to_regen_flow_field = true
    tower.type = tower_type
    if tower_type == TOWER_TYPE.REDEYE then
        tower.range          = 7
        tower.last_shot_time = tower.TOB
        tower.target_index   = false

        state.map[hex.x][hex.y].elevation = 2

    elseif tower_type == TOWER_TYPE.LIGHTHOUSE then
        tower.range = 5
        tower.perimeter = ring_map(tower.hex, tower.range)
        --[[
        tower.node:append(
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
                max_particles = 200
            }
        )
        ]]
        -- @HACK
        need_to_regen_flow_field = false

    elseif tower_type == TOWER_TYPE.WALL then
        state.map[hex.x][hex.y].elevation = 1

    elseif tower_type == TOWER_TYPE.MOAT then
        state.map[hex.x][hex.y].elevation = -1
    end

    if need_to_regen_flow_field then
        generate_and_apply_flow_field(state.map, HEX_GRID_CENTER, state.world)
    end

    register_entity(TOWERS, tower)
end

function build_tower(hex, tower_type)
    update_money(-get_tower_base_cost(tower_type))
    make_and_register_tower(hex, tower_type)
    vplay_sfx(SOUNDS.EXPLOSION4)
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

