

-- @NOTE returns i,v in the table
function mob_on_hex(hex)
    return table.find(ENTITIES, function(entity)
        return entity.type == ENTITY_TYPE.MOB and entity.hex == hex
    end)
end


function mob_die(mob, entity_index)
    WORLD:action(vplay_sound(SOUNDS.EXPLOSION1))
    delete_entity(entity_index)
end

function do_hit_mob(mob, damage, index)
    mob.health = mob.health - damage

    if mob.health < 1 then
        update_score(mob.bounty)
        mob_die(mob, index)
    end
end

function check_for_broken_mob_pathing(hex)
    for _,entity in pairs(ENTITIES) do
        if entity.type == ENTITY_TYPE.MOB and entity.path[hex.x] and entity.path[hex.x][hex.y] then
            --local pathfinder = coroutine.create(function()
                entity.path = get_mob_path(entity, HEX_MAP, entity.hex, HEX_GRID_CENTER)
            --end)
            --coroutine.resume(pathfinder)
        end
    end
end

-- check if a the tile at |hex| is passable by |mob|
local function mob_can_pass_through(mob, hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    return tile and tile.elevation < 0.5 and tile.elevation > -0.5
end

-- @TODO performance.
-- try reducing map size by identifying key nodes (inflection points)
-- there are performance hits everytime we spawn a mob and it's Astar's fault
function get_mob_path(mob, map, start, goal)
    return Astar(map, goal, start,
        -- neighbour function
        function(map, hex)
            return table.filter(grid_neighbours(map, hex), function(_hex)
                return mob_can_pass_through(mob, _hex)
            end)
        end,

        -- heuristic function
        math.distance,

        -- cost function
        function(from, to)
            return math.abs(map.get(from.x, from.y).elevation - map.get(to.x, to.y).elevation)
        end
    )
end

-- @FIXME there's a bug here where the position of the spawn hex is sometimes 1 closer to the center than we want
local function get_spawn_hex()
    local spawn_hex
    repeat
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
        spawn_hex = evenq_to_hex(vec2(x, -y))
        local tile = HEX_MAP[spawn_hex.x][spawn_hex.y]

    until is_passable(tile)

    return spawn_hex
end

local function make_and_register_mob()
    local mob = make_and_register_entity(
        -- type
        ENTITY_TYPE.MOB,

        -- hex spawn position
        get_spawn_hex(),

        -- node
        am.scale(2)
        ^ am.rotate(TIME)
        ^ pack_texture_into_sprite(TEX_MOB1_1, 20, 20),

        -- update
        function(_mob, _mob_index)
            _mob.hex = pixel_to_hex(_mob.position)

            local frame_target = _mob.path[_mob.hex.x] and _mob.path[_mob.hex.x][_mob.hex.y]

            if frame_target then
                _mob.position = _mob.position + math.normalize(hex_to_pixel(frame_target.hex) - _mob.position) * _mob.speed
                _mob.node.position2d = _mob.position

            else
                if _mob.hex == HEX_GRID_CENTER then
                    update_score(-_mob.health)
                    mob_die(_mob, _mob_index)
                else
                    log("stuck")
                end
            end

            -- passive animation
            if math.random() < 0.01 then
                _mob.node"rotate":action(am.tween(0.3, { angle = _mob.node"rotate".angle + math.pi*3 }))
            else
                _mob.node"rotate".angle = math.wrapf(_mob.node"rotate".angle + am.delta_time, math.pi*2)
            end
        end
    )

    mob.path           = get_mob_path(mob, HEX_MAP, mob.hex, HEX_GRID_CENTER)
    mob.health         = 10
    mob.speed          = 1
    mob.bounty         = 5
    mob.hurtbox_radius = 15
end

local SPAWN_CHANCE = 100
function do_mob_spawning()
    --if WIN:key_pressed"space" then
    if math.random(SPAWN_CHANCE) == 1 then
        make_and_register_mob()
    end
end

