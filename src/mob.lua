

MOB_HURTBOX_RADIUS = 4


-- determines when, where, and how often to spawn mobs.
function spawner(world)
    local SPAWN_CHANCE = 25
    if math.random(SPAWN_CHANCE) == 1 then -- chance to spawn
        local spawn_position
        repeat
            -- ensure we spawn on an random tile along the map's edges
            local x,y = math.random(46), math.random(33)
            if math.random() < 0.5 then
                x = math.random(0, 1) * 46
            else
                y = math.random(0, 1) * 33
            end
            spawn_position = offset_to_hex(vec2(x, y))

            -- ensure that we spawn somewhere that is passable: mid-elevation
            local e = map[spawn_position.x][spawn_position.y]
        until e and e < 0.5 and e > -0.5

        local mob = am.translate(-278, -318) ^ am.circle(hex_to_pixel(spawn_position), MOB_HURTBOX_RADIUS)
        world:append(mob"circle":action(coroutine.create(live)))
    end
end

-- this function is the coroutine that represents the life-cycle of a mob.
function live(mob)
    local dead = false

    local visited = {}
    visited[mob.center.x] = {}; visited[mob.center.x][mob.center.y] = true

    -- begin life
    repeat
        local neighbours = hex_neighbours(pixel_to_hex(mob.center))
        local candidates = {}

        -- get list of candidates: hex positions to consider moving to.
        for _,h in pairs(neighbours) do

            local e
            if map[h.x] then
                e = map[h.x][h.y]
            end

            if e and e < 0.5 and e > -0.5 then
                if visited[h.x] then
                    if not visited[h.x][h.y] then
                        table.insert(candidates, h)
                    end
                else
                    table.insert(candidates, h)
                end
            end
        end

        -- choose where to move. manhattan distance closest to goal is chosen.
        local move = candidates[1]
        for _,h in pairs(candidates) do
            if math.distance(h, home.center) < math.distance(move, home.center) then
                move = h
            end
        end

        if not move then print("can't find anywhere to move to"); return
        end -- bug

        local speed = map[move.x][move.y] ^ 2 + 0.5
        am.wait(am.tween(mob, speed, {center=hex_to_pixel(move)}))
        visited[move.x] = {}; visited[move.x][move.y] = true
        if move == home.center then dead = true end
    until dead
    win.scene:remove(mob)
end

