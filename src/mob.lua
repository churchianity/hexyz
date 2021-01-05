

MOBS = {}
--[[
    mob structure:
    {
        TOB         - float     -- time stamp in seconds of when the mob when spawned
        hex         - vec2      -- hexagon the mob is on
        position    - vec2      -- true pixel coordinates
        node        - node      -- the root graph node for this mob
        update      - function  -- function that gets called every frame with itself as an argument
    }
]]

require "extra"
require "sound"

MOB_UPDATES = {
    BEEPER = function(mob, index)
        mob.hex = pixel_to_hex(mob.position)

        local frame_target = mob.path[mob.hex.x] and mob.path[mob.hex.x][mob.hex.y]

        if frame_target then
            mob.position = math.lerpv2(mob.position, hex_to_pixel(frame_target.hex), 0.91)
            mob.node.position2d = mob.position

        else -- can't find path, or dead
            win.scene:action(am.play(am.sfxr_synth(SOUNDS.EXPLOSION1), false, math.random() + 0.5))

            local i,v = table.find(MOBS, function(_mob) return _mob == mob end)
            table.remove(MOBS, index)
            win.scene"world":remove(mob.node)
        end

        -- passive animation
        if math.random() < 0.01 then
            mob.node"rotate":action(am.tween(0.3, { angle = mob.node"rotate".angle + math.pi*3 }))
        else
            mob.node"rotate".angle = math.wrapf(mob.node"rotate".angle + am.delta_time, math.pi*2)
        end
    end
}

-- check if a the tile at |hex| is passable by |mob|
function can_pass_through(mob, hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    return tile and tile.elevation < 0.5 and tile.elevation > -0.5
end

-- @FIXME there's a bug here where the position of the spawn hex is sometimes 1 closer to the center than we want
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

--
function make_mob()
    local mob = {}

    mob.TOB         = TIME
    mob.update      = MOB_UPDATES.BEEPER
    mob.hex         = get_spawn_hex(mob)
    mob.position    = hex_to_pixel(mob.hex)
    mob.path        = Astar(HEX_MAP, HEX_GRID_CENTER, mob.hex,

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
        function(hex)
            return math.abs(HEX_MAP.get(hex.x, hex.y).elevation)
        end
    )

    mob.node = am.translate(mob.position)
               ^ am.scale(2)
               ^ am.rotate(mob.TOB)
               ^ pack_texture_into_sprite(TEX_MOB1_1, 20, 20)

    win.scene"world":append(mob.node)

    return mob
end

local SPAWN_CHANCE = 50
function do_mob_spawning()
    if math.random(SPAWN_CHANCE) == 1 then
        table.insert(MOBS, make_mob())
    end
end

function do_mob_updates()
    for i,mob in pairs(MOBS) do
        mob.update(mob, i)
    end
end

