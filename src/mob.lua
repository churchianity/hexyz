
MOBS = {}

-- check if a the tile at |hex| is passable by |mob|
function can_pass_through(mob, hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    return tile and tile.elevation < 0.5 and tile.elevation > -0.5
end

function get_movement_cost(mob, start_hex, goal_hex)
    return 1
end

function get_spawn_hex(mob)
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

    until can_pass_through(mob, spawn_hex)

    return spawn_hex
end

-- @NOTE spawn hex
function make_mob()
    local mob = {}

    local spawn_hex = get_spawn_hex(mob)
    local spawn_position = hex_to_pixel(spawn_hex) + WORLDSPACE_COORDINATE_OFFSET

    mob.position = spawn_position
    mob.hex = spawn_hex
    mob.path = Astar(HEX_MAP, HEX_GRID_CENTER, spawn_hex,

        -- neighbour function
        function(hex)
            return table.filter(hex_neighbours(hex), function(_hex)
                return can_pass_through(mob, _hex)
            end)
        end,

        -- heuristic function
        function(source, target)
            return math.distance(source, target)
        end,

        -- cost function
        function(map_entry)
            return math.abs(map_entry.elevation)
        end
    )

    mob.sprite = am.circle(spawn_position, 18, COLORS.WHITE, 4)
    win.scene:append(mob.sprite)

    return mob
end

local SPAWN_CHANCE = 25
function do_mob_spawning()
    if win:key_pressed"space" then
    --if math.random(SPAWN_CHANCE) == 1 then
        table.insert(MOBS, make_mob())
    end
end

function do_mob_updates()
    --if win:key_pressed"a" then
    for _,mob in pairs(MOBS) do
        mob.hex = pixel_to_hex(mob.position - WORLDSPACE_COORDINATE_OFFSET)

        local frame_target = map_get(mob.path, mob.hex.x, mob.hex.y)

        if frame_target then
            mob.position = lerp(mob.position, hex_to_pixel(frame_target.hex) + WORLDSPACE_COORDINATE_OFFSET, 0.9)
            mob.sprite.center = mob.position
        else

        end
    end
    --end
end

