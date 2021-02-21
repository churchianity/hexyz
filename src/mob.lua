

state.mobs = {}

MOB_TYPE = {
    BEEPER = 1,
    SPOODER = 2
}

MAX_MOB_SIZE = hex_height(HEX_SIZE, HEX_ORIENTATION.FLAT) / 2
MOB_SIZE = MAX_MOB_SIZE

MOB_SPECS = {
    [MOB_TYPE.BEEPER] = {
        health = 30,
        speed = 8,
        bounty = 15,
        hurtbox_radius = MOB_SIZE/2
    },
    [MOB_TYPE.SPOODER] = {
        health = 20,
        speed = 10,
        bounty = 5,
        hurtbox_radius = MOB_SIZE/2
    }
}

function get_mob_health(mob_type)
    return MOB_SPECS[mob_type].health
end
function get_mob_spec(mob_type)
    return MOB_SPECS[mob_type]
end

local function grow_mob_health(mob_type, spec_health, time)
    return spec_health * (time / 100 + 1)
end
local function grow_mob_speed(mob_type, spec_speed, time)
    -- @TODO maybe speed shouldn't grow with time at all.
    -- if it does, a small amount with a horizontal asymptote
    return spec_speed --* math.abs(math.log(time / 100))
end
local function grow_mob_bounty(mob_type, spec_bounty, time)
    return spec_bounty * (time / 100 + 1)
end

function mobs_on_hex(hex)
    local t = {}
    for mob_index,mob in pairs(state.mobs) do
        if mob and mob.hex == hex then
            table.insert(t, mob_index, mob)
        end
    end
    return t
end

function mob_on_hex(hex)
    -- table.find returns i,v in the table
    return table.find(state.mobs, function(mob)
        return mob and mob.hex == hex
    end)
end

-- check if a the tile at |hex| is passable by |mob|
function mob_can_pass_through(mob, hex)
    local tile = hex_map_get(state.map, hex)
    return tile_is_medium_elevation(tile)
end

function mob_die(mob, mob_index)
    vplay_sfx(SOUNDS.EXPLOSION1)
    delete_entity(state.mobs, mob_index)
end

function mob_reach_center(mob, mob_index)
    update_score(-(mob.health + mob.bounty))
    delete_entity(state.mobs, mob_index)
end

local HEALTHBAR_WIDTH = HEX_PIXEL_WIDTH/2
local HEALTHBAR_HEIGHT = HEALTHBAR_WIDTH/4
function do_hit_mob(mob, damage, mob_index)
    mob.health = mob.health - damage
    if mob.health <= 0 then
        update_score(mob.bounty)
        update_money(mob.bounty)
        mob_die(mob, mob_index)
    else
        mob.healthbar:action(coroutine.create(function(self)
            local x2 = -HEALTHBAR_WIDTH/2 + mob.health/grow_mob_health(mob.type, get_mob_health(mob.type), state.time) * HEALTHBAR_WIDTH/2
            self:child(2).x2 = x2
            self.hidden = false
            am.wait(am.delay(0.8))
            self.hidden = true
        end))
    end
end

function make_mob_node(mob_type, mob)
    local healthbar = am.group{
        am.rect(-HEALTHBAR_WIDTH/2, -HEALTHBAR_HEIGHT/2, HEALTHBAR_WIDTH/2, HEALTHBAR_HEIGHT/2, COLORS.VERY_DARK_GRAY),
        am.rect(-HEALTHBAR_WIDTH/2, -HEALTHBAR_HEIGHT/2, HEALTHBAR_WIDTH/2, HEALTHBAR_HEIGHT/2, COLORS.GREEN_YELLOW)
    }
    healthbar.hidden = true

    if mob_type == MOB_TYPE.BEEPER then
        return am.group{
            am.rotate(am.current_time()) -- state.time is not garunteed to be set when deserializing
            ^ pack_texture_into_sprite(TEXTURES.MOB_BEEPER, MOB_SIZE, MOB_SIZE),
            am.translate(0, -10)
            ^ healthbar
        }
    elseif mob_type == MOB_TYPE.SPOODER then
        return am.group{
            am.rotate(0)
            ^ pack_texture_into_sprite(TEXTURES.MOB_SPOODER, MOB_SIZE, MOB_SIZE),
            am.translate(0, -10)
            ^ healthbar
        }
    end
end

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
    local hex = evenq_to_hex(vec2(x, -y))

    return hex
end

local function resolve_frame_target_for_mob(mob, mob_index)
    local last_frame_hex = mob.hex
    mob.hex = pixel_to_hex(mob.position, vec2(HEX_SIZE))

    if mob.hex == HEX_GRID_CENTER then
        mob_reach_center(mob, mob_index)
        return true
    end

    -- figure out movement
    if last_frame_hex ~= mob.hex or not mob.frame_target then
        local frame_target, tile = false, false
        if mob.path then
            -- we (should) have an explicitly stored target
            local path_entry = hex_map_get(mob.path, mob.hex)

            if not path_entry then
                -- we should be just about to reach the target, delete the path.
                mob.path = false
                mob.frame_target = false
                return
            end

            mob.frame_target = path_entry.hex

            -- check if our target is valid, and if it's not we aren't going to move this frame.
            if last_frame_hex ~= mob.hex and not mob_can_pass_through(mob, mob.frame_target) then
                mob.path = false
                mob.frame_target = false
            end
        else
            -- use the map's flow field - gotta find the the best neighbour
            local neighbours = grid_neighbours(state.map, mob.hex)

            if #neighbours > 0 then
                local first_neighbour = neighbours[1]
                tile = hex_map_get(state.map, first_neighbour)
                local lowest_cost_hex = first_neighbour
                local lowest_cost = tile.priority or 0

                for _,n in pairs(neighbours) do
                    tile = hex_map_get(state.map, n)

                    if not tile.priority then
                        -- if there's no stored priority, that should mean it's the center tile
                        -- in which case, it should be the best target
                        lowest_cost_hex = n
                        break
                    end

                    local current_cost = tile.priority

                    if current_cost and current_cost < lowest_cost then
                        lowest_cost_hex = n
                        lowest_cost = current_cost
                    end
                end

                mob.frame_target = lowest_cost_hex
            else
                --log('no neighbours')
            end
        end
    end
end

local function update_mob_spooder(mob, mob_index)
    resolve_frame_target_for_mob(mob, mob_index)

    if mob.frame_target then
        -- do movement
        -- it's totally possible that the target we have was invalidated by a tower placed this frame,
        -- or between when we last calculated this target and now
        -- check for that now
        if mob_can_pass_through(mob, mob.frame_target) then
            local from = state.map.get(mob.hex.x, mob.hex.y)
            local to = state.map.get(mob.frame_target.x, mob.frame_target.y)
            local rate = (math.abs(from.elevation - to.elevation) * 100) * mob.speed * am.delta_time

            mob.position = mob.position + math.normalize(hex_to_pixel(mob.frame_target, vec2(HEX_SIZE)) - mob.position) * rate
            mob.node.position2d = mob.position
        else
            mob.frame_target = false
        end
    else
        --log('no target')
    end

    -- passive animation
    if math.random() < 0.1 then
        mob.node"rotate":action(am.tween(0.3, { angle = math.random(math.rad(0, -180))}))
    end
end

local function update_mob_beeper(mob, mob_index)
    resolve_frame_target_for_mob(mob, mob_index)

    if mob.frame_target then
        -- do movement
        -- it's totally possible that the target we have was invalidated by a tower placed this frame,
        -- or between when we last calculated this target and now
        -- check for that now
        if mob_can_pass_through(mob, mob.frame_target) then
            local from = hex_map_get(state.map, mob.hex)
            local to = hex_map_get(state.map, mob.frame_target)
            local rate = (4 * mob.speed - math.abs(to.elevation - from.elevation)) * am.delta_time

            mob.position = mob.position + math.normalize(hex_to_pixel(mob.frame_target, vec2(HEX_SIZE)) - mob.position) * rate
            mob.node.position2d = mob.position
        else
            mob.frame_target = false
        end
    else
        --log('no target')
    end

    -- passive animation
    if math.random() < 0.01 then
        mob.node"rotate":action(am.tween(0.3, { angle = mob.node"rotate".angle + math.pi*3 }))
    else
        mob.node"rotate".angle = math.wrapf(mob.node"rotate".angle + am.delta_time, math.pi*2)
    end
end

local function get_mob_update_function(mob_type)
    if mob_type == MOB_TYPE.BEEPER then
        return update_mob_beeper

    elseif mob_type == MOB_TYPE.SPOODER then
        return update_mob_spooder
    end
end

local function make_and_register_mob(mob_type)
    local mob = make_basic_entity(
        get_spawn_hex(),
        get_mob_update_function(mob_type)
    )

    mob.type = mob_type
    mob.node = am.translate(mob.position) ^ make_mob_node(mob_type, mob)

    local spec = get_mob_spec(mob_type)
    mob.health = grow_mob_health(mob_type, spec.health, state.time)
    mob.speed = grow_mob_speed(mob_type, spec.speed, state.time)
    mob.bounty = grow_mob_bounty(mob_type, spec.bounty, state.time)
    mob.hurtbox_radius = spec.hurtbox_radius
    mob.healthbar = mob.node:child(1):child(2):child(1) -- lmao

    register_entity(state.mobs, mob)
    return mob
end

function mob_serialize(mob)
    local serialized = entity_basic_devectored_copy(mob)

    return am.to_json(serialized)
end

function mob_deserialize(json_string)
    local mob = entity_basic_json_parse(json_string)

    mob.update = get_mob_update_function(mob.type)
    mob.node = am.translate(mob.position) ^ make_mob_node(mob.type, mob)
    mob.healthbar = mob.node:child(1):child(2):child(1) -- lmaoooo

    return mob
end

local function can_spawn_mob()
    local MAX_SPAWN_RATE = 0.1
    if not state.spawning or (state.time - state.last_mob_spawn_time) < MAX_SPAWN_RATE then
        return false
    end

    if math.random() <= state.spawn_chance then
        state.last_mob_spawn_time = state.time
        return true
    else
        return false
    end
end

function do_mob_spawning()
    if can_spawn_mob() then
        make_and_register_mob(MOB_TYPE.BEEPER)
    end
end

function do_mob_updates()
    for mob_index,mob in pairs(state.mobs) do
        if mob and mob.update then
            mob.update(mob, mob_index)
        end
    end
end

