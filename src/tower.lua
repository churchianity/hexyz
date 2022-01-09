
local function default_tower_placement_f(blocked, has_water, has_mountain, has_ground, hex)
    return not (blocked or has_water or has_mountain)
end

local function default_weapon_target_acquisition_f(tower, tower_index)
    for index,mob in pairs(game_state.mobs) do
        if mob then
            local d = math.distance(mob.hex, tower.hex)

            for _,w in pairs(tower.weapons) do
                if d <= w.range then
                    tower.target_index = index
                    return
                end
            end
        end
    end
end

local function default_handle_target_f(tower, tower_index, mob)
    -- the target we have is valid
    local vector = math.normalize(mob.position - tower.position)

    for _,w in pairs(tower.weapons) do
        if (game_state.time - w.last_shot_time) > w.fire_rate then
            local projectile = make_and_register_projectile(
                tower.hex,
                w.projectile_type,
                vector
            )

            w.last_shot_time = game_state.time
            play_sfx(w.hit_sound)
        end
    end
end

local function default_tower_update_f(tower, tower_index)
    if not tower.target_index then
        -- try and acquire a target
        default_weapon_target_acquisition_f(tower, tower_index)

    else
        -- check if our current target is invalidated
        local mob = game_state.mobs[tower.target_index]
        if not mob then
            tower.target_index = false

        else
            -- do what we should do with the target
            default_handle_target_f(tower, tower_index, mob)
        end
    end
end

local function default_tower_weapon_target_acquirer_f(tower, tower_index)
end

TOWER_SPECS = {}
TOWER_TYPE = {}
local function make_tower_sprite(t)
    return pack_texture_into_sprite(t.texture, HEX_PIXEL_WIDTH, HEX_PIXEL_HEIGHT)
end
function init_tower_specs()
    local base_tower_specs = {
        {
            id = "WALL",
            name = "Wall",
            placement_rules_text = "Place on Ground",
            short_description = "Restricts movement, similar to a mountain.",
            texture = TEXTURES.TOWER_WALL,
            icon_texture = TEXTURES.TOWER_WALL_ICON,
            cost = 10,
            range = 0,
            fire_rate = 2,
            update_f = false,
            make_node_f = function(self, hex)
                local group = am.group(am.circle(vec2(0), HEX_SIZE, COLORS.VERY_DARK_GRAY, 6))
                if not hex then
                    -- should only happen when making the hex-cursor for the wall
                    return group
                end

                local lines = am.rotate(math.rad(-30)) ^ am.group()
                for i,n in pairs(hex_neighbours(hex)) do
                    local no_walls_adjacent = true

                    for _,t in pairs(towers_on_hex(n)) do
                        if t.type == TOWER_TYPE.WALL then
                            no_walls_adjacent = false
                            break
                        end
                    end

                    if no_walls_adjacent then
                        local p1 = hex_corner_offset(vec2(0), i)
                        local j = i == 6 and 1 or i + 1
                        local p2 = hex_corner_offset(vec2(0), j)
                        lines:append(
                            am.line(p1, p2, HEX_SIZE/4, COLORS.VERY_DARK_GRAY/vec4(vec3((i % 2) == 0 and 2 or 4), 1))
                        )
                    end
                end
                group:append(lines)

                return group
            end
        },
        {
            id = "GATTLER",
            name = "Gattler",
            placement_rules_text = "Place on Ground",
            short_description = "Short-range, fast-fire rate single-target tower.",
            texture = TEXTURES.TOWER_GATTLER,
            icon_texture = TEXTURES.TOWER_GATTLER_ICON,
            cost = 20,
            height = 2,
            weapons = {
                {
                    projectile_type = PROJECTILE_TYPE.BULLET,
                    range = 4,
                    fire_rate = 0.5,
                    hit_sound = SOUNDS.HIT1,
                }
            },
            make_node_f = function(self)
                return am.group(
                    am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 5),
                    am.rotate(game_state.time or 0)
                    ^ pack_texture_into_sprite(self.texture, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2, COLORS.GREEN_YELLOW)
                )
            end,
            update_f = function(tower, tower_index)
                if not tower.target_index then
                    -- we should try and acquire a target
                    default_weapon_target_acquisition_f(tower, tower_index)

                    -- passive animation
                    tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
                else
                    -- should have a target, so we should try and shoot it
                    local mob = game_state.mobs[tower.target_index]
                    if not mob then
                        -- the target we have was invalidated
                        tower.target_index = false

                    else
                        default_handle_target_f(tower, tower_index, mob)

                        -- point the cannon at the dude
                        local theta = math.rad(90) - math.atan((tower.position.y - mob.position.y)/(tower.position.x - mob.position.x))
                        local diff = tower.node("rotate").angle - theta

                        tower.node("rotate").angle = -theta + math.pi/2
                    end
                end
            end
        },
        {
            id = "HOWITZER",
            name = "Howitzer",
            placement_rules_text = "Place on Ground, with a 1 space gap between other towers and mountains - walls/moats don't count.",
            short_description = "Medium-range, medium fire-rate area of effect artillery tower.",
            texture = TEXTURES.TOWER_HOWITZER,
            icon_texture = TEXTURES.TOWER_HOWITZER_ICON,
            cost = 50,
            height = 2,
            weapons = {
                {
                    projectile_type = PROJECTILE_TYPE.SHELL,
                    range = 6,
                    fire_rate = 4,
                    hit_sound = SOUNDS.EXPLOSION2
                }
            },
            make_node_f = function(self)
                return am.group(
                    am.circle(vec2(0), HEX_SIZE - 4, COLORS.VERY_DARK_GRAY, 6),
                    am.rotate(game_state.time or 0) ^ am.group(
                        pack_texture_into_sprite(self.texture, HEX_PIXEL_HEIGHT*1.5, HEX_PIXEL_WIDTH*2) -- CHONK
                    )
                )
            end,
            placement_f = function(blocked, has_water, has_mountain, has_ground, hex)
                local has_mountain_neighbour = false
                local has_non_wall_non_moat_tower_neighbour = false

                for _,h in pairs(hex_neighbours(hex)) do
                    local towers = towers_on_hex(h)
                    local wall_on_hex = false

                    has_non_wall_non_moat_tower_neighbour = table.find(towers, function(tower)
                        if tower.type == TOWER_TYPE.WALL then
                            wall_on_hex = true
                            return false

                        elseif tower.type == TOWER_TYPE.MOAT then
                            return false
                        end

                        return true
                    end)

                    if has_non_wall_non_moat_tower_neighbour then
                        break
                    end

                    local tile = hex_map_get(game_state.map, h)
                    if not wall_on_hex and tile and tile.elevation >= 0.5 then
                        has_mountain_neighbour = true
                        break
                    end
                end
                return not (blocked or has_water or has_mountain or has_mountain_neighbour or has_non_wall_non_moat_tower_neighbour)
            end,
            update_f = function(tower, tower_index)
                if not tower.target_index then
                    default_weapon_target_acquisition_f(tower, tower_index)

                    -- passive animation
                    tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
                else
                    -- we should have a target
                    local mob = game_state.mobs[tower.target_index]
                    if not mob then
                        -- the target we have was invalidated
                        tower.target_index = false

                    else
                        default_handle_target_f(tower, tower_index, mob)

                        -- point the cannon at the dude
                        local theta = math.rad(90) - math.atan((tower.position.y - mob.position.y)/(tower.position.x - mob.position.x))
                        local diff = tower.node("rotate").angle - theta

                        tower.node("rotate").angle = -theta + math.pi/2
                    end
                end
            end
        },
        {
            id = "REDEYE",
            name = "Redeye",
            placement_rules_text = "Place on Mountains.",
            short_description = "Long-range, penetrating high-velocity laser tower.",
            texture = TEXTURES.TOWER_REDEYE,
            icon_texture = TEXTURES.TOWER_REDEYE_ICON,
            cost = 75,
            height = 2,
            weapons = {
                {
                    projectile_type = PROJECTILE_TYPE.LASER,
                    range = 9,
                    fire_rate = 3,
                    hit_sound = SOUNDS.LASER2
                }
            },
            make_node_f = function(self)
                return make_tower_sprite(self)
            end,
            placement_f = function(blocked, has_water, has_mountain, has_ground, hex)
                return not blocked and has_mountain
            end,
            update_f = default_tower_update_f
        },
        {
            id = "MOAT",
            name = "Moat",
            placement_rules_text = "Place on Ground",
            short_description = "Restricts movement, similar to water.",
            texture = TEXTURES.TOWER_MOAT,
            icon_texture = TEXTURES.TOWER_MOAT_ICON,
            cost = 10,
            range = 0,
            fire_rate = 2,
            height = -1,
            make_node_f = function(self)
                return am.circle(vec2(0), HEX_SIZE, COLORS.WATER{a=1}, 6)
            end,
            update_f = false
        },
        {
            id = "RADAR",
            name = "Radar",
            placement_rules_text = "n/a",
            short_description = "Doesn't do anything right now :(",
            texture = TEXTURES.TOWER_RADAR,
            icon_texture = TEXTURES.TOWER_RADAR_ICON,
            cost = 100,
            range = 0,
            fire_rate = 1,
            make_node_f = function(self)
                return make_tower_sprite(self)
            end,
            update_f = false
        },
        {
            id = "LIGHTHOUSE",
            name = "Lighthouse",
            placement_rules_text = "Place on Ground, adjacent to Water or Moats",
            short_description = "Attracts nearby mobs; temporarily redirects their path",
            texture = TEXTURES.TOWER_LIGHTHOUSE,
            icon_texture = TEXTURES.TOWER_LIGHTHOUSE_ICON,
            cost = 150,
            range = 7,
            fire_rate = 1,
            height = 2,
            make_node_f = function(self)
                return am.group(
                    make_tower_sprite(self),
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
                )
            end,
            placement_f = function(blocked, has_water, has_mountain, has_ground, hex)
                local has_water_neighbour = false
                for _,h in pairs(hex_neighbours(hex)) do
                    local tile = hex_map_get(game_state.map, h)

                    if tile and tile.elevation < -0.5 then
                        has_water_neighbour = true
                        break
                    end
                end
                return not blocked
                    and not has_mountain
                    and not has_water
                    and has_water_neighbour
            end,
            update_f = function(tower, tower_index)
                -- check if there's a mob on a hex in our perimeter
                for _,h in pairs(tower.perimeter) do
                    local mobs = mobs_on_hex(h)

                    for _,m in pairs(mobs) do
                        if not m.path and not m.seen_lighthouse then
                            -- @TODO only attract the mob if its frame target (direction vector)
                            -- is within some angle range...? if the mob is heading directly away from the tower, then
                            -- the lighthouse shouldn't do much

                            local path, made_it = hex_Astar(game_state.map, tower.hex, m.hex, grid_neighbours, grid_cost, grid_heuristic)

                            if made_it then
                                m.path = path
                                m.seen_lighthouse = true -- right now mobs don't care about lighthouses if they've already seen one.
                            end
                        end
                    end
                end
            end
        },
        {
            id = "FARM",
            name = "Farm",
            placement_rules_text = "Place on Ground",
            short_description = "Increases income gained over time. Mobs can trample farms, reducing their income (never completely nullifying it).",
            texture = TEXTURES.TOWER_FARM,
            icon_texture = TEXTURES.TOWER_FARM_ICON,
            cost = 50,
            size = 2,
            height = 0,
            make_node_f = function(self)
                local quads = am.quads(2*7, {"vert", "vec2", "uv", "vec2", "color", "vec4"})

                local map = hex_spiral_map(vec2(0), 1)
                for _,h in pairs(map) do
                    make_hex_quads_node(quads, hex_to_pixel(h))
                end

                return am.blend("alpha") ^ am.use_program(make_hex_shader_program_node()) ^ am.bind{ texture = TEXTURES.TOWER_FARM } ^ quads
            end
        }
    }

    -- initialize the tower cursors (what you see when you select a tower and hover over buildable hexes)
    local tower_cursors = {}
    for i,t in pairs(base_tower_specs) do
        TOWER_TYPE[t.id] = i

        if not t.size then      t.size = 1 end
        if not t.height then    t.height = 1 end

        if not t.update_f then
            t.update_f = default_tower_update_f
        end
        if not t.placement_f then
            t.placement_f = default_tower_placement_f
        end

        if not t.weapons then
            t.weapons = {}
        end
        -- resolve missing fields among weapons the tower has, as well as
        -- the tower's visual range - if not provided we should use the largest range among weapons it has
        local largest_range = 0
        local largest_minimum_range = 0
        for i,w in pairs(t.weapons) do
            if not w.min_range then
                w.min_range = 0
            end
            if not w.target_acquisition_f then
                w.target_acquisition_f = default_weapon_target_acquisition_f
            end
            if w.range > largest_range then
                largest_range = w.range
            end
            if w.min_range > largest_minimum_range then
                largest_minimum_range = w.min_range
            end
        end
        if not t.min_visual_range then
            t.min_visual_range = largest_minimum_range
        end
        if not t.visual_range then
            t.visual_range = largest_range
        end

        -- build tower cursors
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

        local tower_sprite = t.make_node_f(t)
        tower_sprite.color = COLORS.TRANSPARENT3
        tower_cursors[i] = am.group(
            make_hex_cursor_node(t.visual_range - 1, vec4(0), coroutine_, t.min_visual_range - 1),
            tower_sprite
        ):tag"cursor"

        function get_tower_cursor(tower_type)
            return tower_cursors[tower_type]
        end
    end

    TOWER_SPECS = base_tower_specs
end

function get_tower_spec(tower_type)                 return TOWER_SPECS[tower_type] end
function get_tower_name(tower_type)                 return TOWER_SPECS[tower_type].name end
function get_tower_cost(tower_type)                 return TOWER_SPECS[tower_type].cost end
function get_tower_size(tower_type)                 return TOWER_SPECS[tower_type].size end
function get_tower_icon_texture(tower_type)         return TOWER_SPECS[tower_type].icon_texture end
function get_tower_placement_rules_text(tower_type) return TOWER_SPECS[tower_type].placement_rules_text end
function get_tower_short_description(tower_type)    return TOWER_SPECS[tower_type].short_description end
function get_tower_update_function(tower_type)      return TOWER_SPECS[tower_type].update_f end

function tower_serialize(tower)
    local serialized = entity_basic_devectored_copy(tower)

    for i,h in pairs(tower.hexes) do
        serialized.hexes[i] = { h.x, h.y }
    end

    return am.to_json(serialized)
end

function tower_deserialize(json_string)
    local tower = entity_basic_json_parse(json_string)

    -- @HACK weapons.last_shot_time field gets overrided with this merge, which we don't want
    local weapons = tower.weapons
    table.merge(tower, get_tower_spec(tower.type))
    tower.weapons = weapons

    for i,h in pairs(tower.hexes) do
        tower.hexes[i] = vec2(tower.hexes[i][1], tower.hexes[i][2])
    end

    tower.update = get_tower_update_function(tower.type)
    tower.node = am.translate(tower.position) ^ tower.make_node_f(tower)

    return tower
end

-- note that the table returned has towers at their index into the global towers table,
-- so #t will often not work correctly (the table will often be sparse)
function towers_on_hex(hex)
    local t = {}
    for tower_index,tower in pairs(game_state.towers) do
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
    return table.find(game_state.towers, function(tower)
        for _,h in pairs(tower.hexes) do
            if h == hex then return true end
        end
    end)
end

function tower_type_is_buildable_on(hex, tile, tower_type)
    -- this function gets polled a lot, and sometimes with nil/false tower types
    if not tower_type then return false end

    -- you can't build anything in the center, probably ever?
    if hex == HEX_GRID_CENTER then return false end

    local blocking_towers = {}
    local blocking_mobs = {}
    local has_water = false
    local has_mountain = false
    local has_ground = false
    local tower_spec = get_tower_spec(tower_type)

    for _,h in pairs(hex_spiral_map(hex, get_tower_size(tower_type) - 1)) do
        if h == HEX_GRID_CENTER then return false end

        table.merge(blocking_towers, towers_on_hex(h))
        table.merge(blocking_mobs, mobs_on_hex(h))

        local tile = hex_map_get(game_state.map, h)
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

    return tower_spec.placement_f(blocked, has_water, has_mountain, has_ground, hex)
end

function make_and_register_tower(hex, tower_type)
    local spec = get_tower_spec(tower_type)
    local tower = make_basic_entity(
        hex,
        spec.update_f
    )

    table.merge(tower, spec)
    tower.type = tower_type
    tower.node = am.translate(tower.position) ^ tower.make_node_f(tower, hex)

    -- initialize each weapons' last shot time to the negation of the fire rate -
    -- this lets the tower fire immediately upon being placed
    for _,w in pairs(tower.weapons) do
        w.last_shot_time = -w.fire_rate
    end

    -- set the tower's hexes - a list of hexes which the tower sits atop
    if tower.size == 1 then
        tower.hexes = { tower.hex }
    else
        tower.hexes = hex_spiral_map(tower.hex, tower.size - 1)
    end

    register_entity(game_state.towers, tower)
    return tower
end

function build_tower(hex, tower_type)
    local tower = make_and_register_tower(hex, tower_type)

    -- building a wall can change the adjancencies between towers, which affects what we should render
    -- check for that now
    for _,t in pairs(game_state.towers) do
        if t ~= tower and t.type == TOWER_TYPE.WALL then
            t.node:replace("group", t.make_node_f(t, t.hex))
        end
    end

    -- modify the hexes the tower sits atop to be impassable (actually just taller by the tower's height value)
    for _,h in pairs(tower.hexes) do
        local tile = hex_map_get(game_state.map, h.x, h.y)
        tile.elevation = tile.elevation + tower.height
    end

    vplay_sfx(SOUNDS.EXPLOSION4)

    return tower
end

function do_tower_updates()
    for tower_index,tower in pairs(game_state.towers) do
        if tower and tower.update then
            tower.update_f(tower, tower_index)
        end
    end
end

