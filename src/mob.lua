

MOBS = {}

MAX_MOB_SIZE = hex_height(HEX_SIZE, ORIENTATION.FLAT) / 2
MOB_SIZE = MAX_MOB_SIZE

function mobs_on_hex(hex)
    local t = {}
    for mob_index,mob in pairs(MOBS) do
        if mob and mob.hex == hex then
            table.insert(t, mob_index, mob)
        end
    end
    return t
end

-- @NOTE returns i,v in the table
function mob_on_hex(hex)
    return table.find(MOBS, function(mob)
        return mob and mob.hex == hex
    end)
end

-- check if a the tile at |hex| is passable by |mob|
function mob_can_pass_through(mob, hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    return tile and tile_is_medium_elevation(tile)
end

function mob_die(mob, mob_index)
    vplay_sfx(SOUNDS.EXPLOSION1)
    delete_entity(MOBS, mob_index)
end

function do_hit_mob(mob, damage, mob_index)
    mob.health = mob.health - damage
    if mob.health <= 0 then
        update_score(mob.bounty)
        update_money(mob.bounty)
        mob_die(mob, mob_index)
    end
end

-- @TODO performance.
-- try reducing map size by identifying key nodes (inflection points)
-- there are performance hits everytime we spawn a mob and it's Astar's fault
function get_mob_path(mob, map, start, goal)
    return Astar(map, goal, start, grid_heuristic, grid_cost)
end

-- @FIXME there's a bug here where the position of the spawn hex is sometimes 1 closer to the center than we want
local function get_spawn_hex()
    -- ensure we spawn on an random tile along the map's edges
    local roll = math.random(HEX_GRID_WIDTH * 2 + HEX_GRID_HEIGHT * 2) - 1
    local x, y

    if roll < HEX_GRID_HEIGHT then
        x, y = 0, roll

    elseif roll < (HEX_GRID_WIDTH + HEX_GRID_HEIGHT) then
        x, y = roll - HEX_GRID_HEIGHT, HEX_GRID_HEIGHT - 1

    elseif roll < (HEX_GRID_HEIGHT * 2 + HEX_GRID_WIDTH) then
        x, y = HEX_GRID_WIDTH - 1, roll - HEX_GRID_WIDTH - HEX_GRID_HEIGHT

    else
        x, y = roll - (HEX_GRID_HEIGHT * 2) - HEX_GRID_WIDTH, 0
    end

    -- @NOTE negate 'y' because hexyz algorithms assume south is positive, in amulet north is positive
    return evenq_to_hex(vec2(x, -y))
end

local function update_mob(mob, mob_index)
    local last_frame_hex = mob.hex
    mob.hex = pixel_to_hex(mob.position)

    if mob.hex == HEX_GRID_CENTER then
        update_score(-mob.health)
        mob_die(mob, mob_index)
        return true
    end

    -- figure out movement
    if last_frame_hex ~= mob.hex or not mob.frame_target then
        local frame_target, tile = nil, nil
        if mob.path then
            --log('A*')
            -- we have an explicitly stored target
            local path_entry = mob.path[mob.hex.x] and mob.path[mob.hex.x][mob.hex.y]

            if not path_entry then
                -- we should be just about to reach the target, delete the path.
                mob.path = nil
                mob.frame_target = nil
                return
            end

            mob.frame_target = path_entry.hex

            -- check if our target is valid, and if it's not we aren't going to move this frame.
            -- recalculate our path.
            if last_frame_hex ~= mob.hex and not mob_can_pass_through(mob, mob.frame_target) then
                log('recalc')
                mob.path = get_mob_path(mob, HEX_MAP, mob.hex, HEX_GRID_CENTER)
                mob.frame_target = nil
            end
        else
            -- use the map's flow field - gotta find the the best neighbour
            local neighbours = state.map.neighbours(mob.hex)

            if #neighbours > 0 then
                local first_neighbour = neighbours[1]
                tile = state.map.get(first_neighbour.x, first_neighbour.y)
                local lowest_cost_hex = first_neighbour
                local lowest_cost = tile.priority or 0

                for _,n in pairs(neighbours) do
                    tile = state.map.get(n.x, n.y)
                    local current_cost = tile.priority

                    if current_cost and current_cost < lowest_cost then
                        lowest_cost_hex = n
                        lowest_cost = current_cost
                    end
                end

                mob.frame_target = lowest_cost_hex
            else
                log('no neighbours')
            end
        end
    end

    if mob.frame_target and mob.frame_target == last_frame_hex then
        --log('backpedaling')
    end

    -- do movement
    if mob.frame_target then
        -- this is supposed to achieve frame rate independence, but i have no idea if it actually does
        -- the constant multiplier at the beginning is how many pixels we want a mob with speed 1 to move in one frame
        local rate = 4 * mob.speed / state.perf.avg_fps

        mob.position = mob.position + math.normalize(hex_to_pixel(mob.frame_target) - mob.position) * rate
        mob.node.position2d = mob.position
    else
        log('no target')
    end

    -- passive animation
    if math.random() < 0.01 then
        mob.node"rotate":action(am.tween(0.3, { angle = mob.node"rotate".angle + math.pi*3 }))
    else
        mob.node"rotate".angle = math.wrapf(mob.node"rotate".angle + am.delta_time, math.pi*2)
    end
end

local function make_and_register_mob(mob_type)
    local mob = make_basic_entity(
        get_spawn_hex(),
        am.rotate(state.time) ^ pack_texture_into_sprite(TEXTURES.MOB_BEEPER, MOB_SIZE, MOB_SIZE),
        update_mob
    )

    --mob.path           = get_mob_path(mob, HEX_MAP, mob.hex, HEX_GRID_CENTER)
    mob.health         = 10
    mob.speed          = 10
    mob.bounty         = 5
    mob.hurtbox_radius = MOB_SIZE/2

    register_entity(MOBS, mob)
end

local SPAWN_CHANCE = 45
function do_mob_spawning()
    --if WIN:key_pressed"space" then
    if math.random(SPAWN_CHANCE) == 1 then
    --if #MOBS < 1 then
        make_and_register_mob()
    end
end

function delete_all_mobs()
    for mob_index,mob in pairs(MOBS) do
        if mob then delete_entity(MOBS, mob_index) end
    end
end

function do_mob_updates()
    for mob_index,mob in pairs(MOBS) do
        if mob and mob.update then
            mob.update(mob, mob_index)
        end
    end
end

