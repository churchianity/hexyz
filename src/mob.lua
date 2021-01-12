

--[[
mob(entity) structure:
{
    path            - 2d table  - map of hexes to other hexes, forms a path
    speed           - number    - multiplier on distance travelled per frame, up to the update function to use correctly
    bounty          - number    - score bonus you get when this mob is killed
    hurtbox_radius  - number    -
}
--]]

MAX_MOB_SIZE = hex_height(HEX_SIZE, ORIENTATION.FLAT) / 2
MOB_SIZE = MAX_MOB_SIZE/2

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
    return tile and tile.elevation <= 0.5 and tile.elevation > -0.5
end

function mob_die(mob, mob_index)
    WORLD:action(vplay_sound(SOUNDS.EXPLOSION1))
    delete_entity(MOBS, mob_index)
end

function do_hit_mob(mob, damage, mob_index)
    mob.health = mob.health - damage
    if mob.health <= 0 then
        update_score(mob.bounty)
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

local function mob_update(mob, mob_index)
    local last_frame_hex = mob.hex
    mob.hex = pixel_to_hex(mob.position)

    if mob.hex == HEX_GRID_CENTER then
        update_score(-mob.health)
        mob_die(mob, mob_index)
        return true
    end

    local frame_target = mob.path[mob.hex.x] and mob.path[mob.hex.x][mob.hex.y]
    -- frame_target will be false when we are one hex away from the center,
    -- or nil if something went wrong
    if not frame_target then
        frame_target = { hex = HEX_GRID_CENTER, priority = 0 }
    end

    if mob_can_pass_through(mob, frame_target.hex) then
        -- this is supposed to achieve frame rate independence, but i have no idea if it actually does
        local rate = 1 + mob.speed * (1/frame_target.priority) / PERF_STATS.avg_fps

        mob.position = mob.position + math.normalize(hex_to_pixel(frame_target.hex) - mob.position) * rate
        mob.node.position2d = mob.position

    else
        mob.path = get_mob_path(mob, HEX_MAP, mob.hex, HEX_GRID_CENTER)
    end

    --[[ passive animation
    if math.random() < 0.01 then
        mob.node"rotate":action(am.tween(0.3, { angle = mob.node"rotate".angle + math.pi*3 }))
    else
        mob.node"rotate".angle = math.wrapf(mob.node"rotate".angle + am.delta_time, math.pi*2)
    end
    --]]
end

local function make_and_register_mob()
    local mob = make_basic_entity(
        get_spawn_hex(),
        am.circle(vec2(0), MOB_SIZE, COLORS.SUNRAY),
        mob_update
    )

    mob.path           = get_mob_path(mob, HEX_MAP, mob.hex, HEX_GRID_CENTER)
    mob.health         = 10
    mob.speed          = 100
    mob.bounty         = 5
    mob.hurtbox_radius = MOB_SIZE

    register_entity(MOBS, mob)
end

local SPAWN_CHANCE = 25
function do_mob_spawning()
    --if WIN:key_pressed"space" then
    if math.random(SPAWN_CHANCE) == 1 then
    --if #MOBS < 1 then
        make_and_register_mob()
    end
end

