
MOBS = {}

-- check if a |tile| is passable by |mob|
function can_pass_through(mob, tile)
    return tile.elevation < 0.5 and tile.elevation > -0.5
end

function get_movement_cost(mob, start_hex, goal_hex)
    return 1
end



function Astar(mob, start_hex, goal_hex)
    local function heuristic(start_hex, goal_hex)
        return math.distance(start_hex, goal_hex)
    end

    local came_from = {}
    came_from[start_hex.x] = {}
    came_from[start_hex.x][start_hex.y] = false

    local frontier = {}
    frontier[1] = { position = start_hex, priority = 0 }

    local cost_so_far = {}
    cost_so_far[start_hex.x] = {}
    cost_so_far[start_hex.x][start_hex.y] = 0

    while not (#frontier == 0) do
        local current = table.remove(frontier, 1)


        if current.position == goal_hex then log('found it!') break end

        for _,_next in pairs(hex_neighbours(current.position)) do
            local tile = get_tile(_next.x, _next.y)

            if tile then
                local new_cost = cost_so_far[current.position.x][current.position.y]
                               + get_movement_cost(mob, current.position, _next)

                if not twoD_get(cost_so_far, _next.x, _next.y) or new_cost < twoD_get(cost_so_far, _next.x, _next.y) then
                    twoD_set(cost_so_far, _next.x, _next.y, new_cost)
                    local priority = new_cost + heuristic(goal_hex, _next)
                    table.insert(frontier, { position = _next, priority = priority })
                    twoD_set(came_from, _next.x, _next.y, current)
                end
            end
        end

    end
    return came_from
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

    until can_pass_through(mob, tile)

    return spawn_hex
end

function make_mob()
    local mob = {}

    local spawn_hex = get_spawn_hex(mob)
    local spawn_position = hex_to_pixel(spawn_hex) + WORLDSPACE_COORDINATE_OFFSET

    mob.position = spawn_position
    mob.path = Astar(mob, spawn_hex, HEX_GRID_CENTER)
    mob.sprite = am.circle(spawn_position, 18, COLORS.WHITE, 4)

    win.scene:action(coroutine.create(function()
        local goal = spawn_hex
        local current = mob.path[HEX_GRID_CENTER.x][HEX_GRID_CENTER.y].position
        log(current)

        while current ~= goal do
            if current then
                win.scene:append(am.circle(hex_to_pixel(current) + WORLDSPACE_COORDINATE_OFFSET, 4, COLORS.MAGENTA))
                current = mob.path[current.x][current.y].position
            end
            am.wait(am.delay(0.01))
        end
    end))

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
    for _,mob in pairs(MOBS) do

    end
end

