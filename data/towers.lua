--[[
    the following is a list of tower specifications, which are declarations of a variety of properties describing what a tower is, and how it functions
    this a lua file. a quick run-down of what writing code in lua looks like: https://www.amulet.xyz/doc/#lua-primer

    each tower spec is a lua table. lua tables are the thing that you use to represent bundles of data (both arrays and hashtables are represented by tables)

    the format of the bundles in our case are described below.
    some propreties are optional. required properties are marked with an asterisk (*), and are generally included at the top of the list.

    # TOWER SPEC TABLE
    | --------------------------| -------- | -------------------------------------------------------------- |
    | property name, required*  | datatype | general description / details                                  |
    | --------------------------| -------- | -------------------------------------------------------------- |
    | name*                     | string   | exact one-line display name text of the tower                  |
    | placement_rules_text*     | string   | one-line description of the placement rules for this tower     |
    | short_description*        | string   | one-line description of the nature of this tower               |
    | texture*                  | userdata | @TODO                                                          |
    | icon_texture*             | userdata | @TODO                                                          |
    | cost*                     | number   | the starting cost of placing this tower                        |
    |                           |          |                                                                |
    | weapons*                  | table    | an array of weapons.                                           |
    |                           |          | order matters - two weapons share a 'choke' value, and both    |
    |                           |          | could acquire a target in a frame, the first one is choosen.   |
    |                           |          |                                                                |
    | placement_f               | function |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    | visual_range              | number   | when the tower has multiple weapons, what range represents the |
    |                           |          | overall range of the tower. default is calculated on load as   |
    |                           |          | the largest range among the weapons the tower has.             |
    | min_visual_range          | number   | same as above but the largest minimum range among weapons      |
    |                           |          |                                                                |
    | update_f                  | function | default value is complicated @TODO                             |
    | grow_f                    | function | default value is false/nil. @TODO                              |
    | size                      | number   | default value of 1, which means the tower occupies one hex.    |
    | height                    | number   | default value of 1. height is relevant for mob pathing and     |
    |                           |          | projectile collision                                           |
    |                           |          |                                                                |
    | --------------------------| -------- | -------------------------------------------------------------- |

    # WEAPON TABLE
    | --------------------------| -------- | -------------------------------------------------------------- |
    | property name, required*  | datatype | general description / details                                  |
    | --------------------------| -------- | -------------------------------------------------------------- |
    | type                      | number   | sometimes, instead of specifying everything for a weapon, it's |
    |                           |          | convenient to refer to a base type. if this is provided all of |
    |                           |          | the weapon's other fields will be initialized to preset values |
    |                           |          | and any other values you provide with the weapon spec will     |
    |                           |          | overwrite those preset values.                                 |
    |                           |          | if you provide a value here, all other properties become       |
    |                           |          | optional.                                                      |
    |                           |          | values you can provide, and what they mean:                    |
    |                           |          |   @TODO                                                        |
    |                           |          |                                                                |
    | fire_rate*                | number   | 'shots' per second, if the weapon has a valid target           |
    | range*                    | number   | max distance (in hexes) at which this weapon acquires targets  |
    |                           |          |                                                                |
    | min-range                 | number   | default of 0. min distance (in hexes) at which this weapon acquires targets  |
    | target_acquisition_f      | function | default value is complicated @TODO                             |
    | choke                     | number   | default of false/nil. @TODO                                    |
    |                           |          |                                                                |
    | --------------------------| -------- | -------------------------------------------------------------- |
]]

return {
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
        update = false,
    },
    {
        id = "GATTLER",
        name = "Gattler",
        placement_rules_text = "Place on Ground",
        short_description = "Short-range, fast-fire rate single-target tower.",
        texture = TEXTURES.TOWER_GATTLER,
        icon_texture = TEXTURES.TOWER_GATTLER_ICON,
        cost = 20,
        weapons = {
            {
                range = 4,
                fire_rate = 0.5,
                projectile_type = 3,
            }
        },
        update = function(tower, tower_index)
            if not tower.target_index then
                -- we should try and acquire a target


                -- passive animation
                tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
            else
                -- should have a target, so we should try and shoot it
                if not game_state.mobs[tower.target_index] then
                    -- the target we have was invalidated
                    tower.target_index = false

                else
                    -- the target we have is valid
                    local mob = game_state.mobs[tower.target_index]
                    local vector = math.normalize(mob.position - tower.position)

                    if (game_state.time - tower.last_shot_time) > tower.fire_rate then
                        local projectile = make_and_register_projectile(
                            tower.hex,
                            PROJECTILE_TYPE.BULLET,
                            vector
                        )

                        tower.last_shot_time = game_state.time
                        play_sfx(SOUNDS.HIT1)
                    end

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
        weapons = {
            {
                range = 6,
                fire_rate = 4,
                projectile_type = 1,
            }
        },
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
        update = function(tower, tower_index)
            if not tower.target_index then
                -- we don't have a target
                for index,mob in pairs(game_state.mobs) do
                    if mob then
                        local d = math.distance(mob.hex, tower.hex)
                        if d <= tower.range then
                            tower.target_index = index
                            break
                        end
                    end
                end

                -- passive animation
                tower.node("rotate").angle = math.wrapf(tower.node("rotate").angle + 0.1 * am.delta_time, math.pi*2)
            else
                -- we should have a target
                -- @NOTE don't compare to false, empty indexes appear on game reload
                if not game_state.mobs[tower.target_index] then
                    -- the target we have was invalidated
                    tower.target_index = false

                else
                    -- the target we have is valid
                    local mob = game_state.mobs[tower.target_index]
                    local vector = math.normalize(mob.position - tower.position)

                    if (game_state.time - tower.last_shot_time) > tower.fire_rate then
                        local projectile = make_and_register_projectile(
                            tower.hex,
                            PROJECTILE_TYPE.SHELL,
                            vector
                        )

                        -- @HACK, the projectile will explode if it encounters something taller than it,
                        -- but the tower it spawns on quickly becomes taller than it, so we just pad it
                        -- if it's not enough the shell explodes before it leaves its spawning hex
                        projectile.props.z = tower.props.z + 0.1

                        tower.last_shot_time = game_state.time
                        play_sfx(SOUNDS.EXPLOSION2)
                    end

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
        weapons = {
            {
                range = 9,
                fire_rate = 3,
                projectile_type = 2,
            }
        },
        placement_f = function(blocked, has_water, has_mountain, has_ground, hex)
            return not blocked and has_mountain
        end,
        update = function(tower, tower_index)
            if not tower.target_index then
                for index,mob in pairs(game_state.mobs) do
                    if mob then
                        local d = math.distance(mob.hex, tower.hex)
                        if d <= tower.range then
                            tower.target_index = index
                            break
                        end
                    end
                end
            else
                if not game_state.mobs[tower.target_index] then
                    tower.target_index = false

                elseif (game_state.time - tower.last_shot_time) > tower.fire_rate then
                    local mob = game_state.mobs[tower.target_index]

                    make_and_register_projectile(
                        tower.hex,
                        PROJECTILE_TYPE.LASER,
                        math.normalize(mob.position - tower.position)
                    )

                    tower.last_shot_time = game_state.time
                    vplay_sfx(SOUNDS.LASER2)
                end
            end
        end
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
        update = false
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
        update = false
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
        update = function(tower, tower_index)
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
}

