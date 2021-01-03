
MOBS = {}

-- check if a |tile| is passable by |mob|
function can_pass_through(mob, tile)
    return tile and tile.elevation and tile.elevation < 0.5 and tile.elevation > -0.5
end

function get_path(mob, starting_hex, goal_hex)
    local moves = {}

    local visited = {}
    visited[starting_hex.x] = {}
    visited[starting_hex.x][starting_hex.y] = true

    repeat
        local neighbours = hex_neighbours(pixel_to_hex(mob.position))
        local candidates = {}

        -- get list of candidates: hex positions to consider moving to.
        for _,neighbour in pairs(neighbours) do
            if can_pass_through(mob, get_tile(neighbour.x, neighbour.y)) then
                if not (visited[neighbour.h] and visited[neighbour.x][neighbour.y]) then
                    table.insert(candidates, neighbour)
                else
                    --table.insert(candidates, neighbour)
                end
            end
        end

        -- choose where to move
        local move = candidates[1]
        for _,hex in pairs(candidates) do
            if math.distance(hex, goal_hex) < math.distance(move, goal_hex) then
                move = hex
            end
        end

        if move then
            table.insert(moves, move)
            visited[move.x] = {}
            visited[move.x][move.y] = true
        end

        --if move == goal then log('made it!') return end
    until move == goal_hex

    return moves
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
    log(spawn_hex)
    local spawn_position = hex_to_pixel(spawn_hex) + WORLDSPACE_COORDINATE_OFFSET

    mob.position = spawn_position
    --mob.path = get_path(mob, spawn_hex, HEX_GRID_CENTER)
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
    for _,mob in pairs(MOBS) do

    end
end

