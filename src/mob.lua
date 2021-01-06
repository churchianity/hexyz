

local MOBS = {}
--[[
    mob structure:
    {
        TOB         - float     -- time stamp in seconds of when the tower was spawned
        hex         - vec2      -- hexagon the mob is on
        position    - vec2      -- true pixel coordinates
        node        - node      -- the root graph node for this mob
        update      - function  -- function that gets called every frame with itself as an argument
        path        - 2d table  -- map of hexes to other hexes, forms a path
        speed       - number    -- multiplier on distance travelled per frame, up to the update function to use correctly
    }
]]

require "extra"
require "sound"


local MOB_UPDATES = {
    BEEPER = function(mob, index)
        mob.hex = pixel_to_hex(mob.position)

        local frame_target = mob.path[mob.hex.x] and mob.path[mob.hex.x][mob.hex.y]

        if frame_target then
            mob.position = mob.position + math.normalize(hex_to_pixel(frame_target.hex) - mob.position) * mob.speed
            mob.node.position2d = mob.position

        else
            if mob.hex == HEX_GRID_CENTER then
                WIN.scene"world":action(
                    am.play(am.sfxr_synth(SOUNDS.EXPLOSION1), false, math.random() + 0.5)
                )

                table.remove(MOBS, index)
                WIN.scene"world":remove(mob.node)
            else
                log("stuck")
            end
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
local function mob_can_pass_through(mob, hex)
    local tile = HEX_MAP.get(hex.x, hex.y)
    return tile and tile.elevation < 0.5 and tile.elevation > -0.5
end

local function get_mob_path(map, start, goal, mob)
    return Astar(map, goal, start, -- goal and start are switched intentionally
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
            return math.abs(map.get(to.x, to.y).elevation)
        end
    )
end

-- @FIXME there's a bug here where the position of the spawn hex is sometimes 1 closer to the center than we want
local function get_spawn_hex(mob)
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

    until mob_can_pass_through(mob, spawn_hex)

    return spawn_hex
end

local function make_mob()
    local mob = {}

    mob.TOB         = TIME
    mob.update      = MOB_UPDATES.BEEPER
    mob.hex         = get_spawn_hex(mob)
    mob.position    = hex_to_pixel(mob.hex)
    mob.path        = get_mob_path(HEX_MAP, mob.hex, HEX_GRID_CENTER, mob)
    mob.speed       = 10

    mob.node = am.translate(mob.position)
               ^ am.scale(2)
               ^ am.rotate(mob.TOB)
               ^ pack_texture_into_sprite(TEX_MOB1_1, 20, 20)

    WIN.scene"world":append(mob.node)

    return mob
end

function mob_on_hex(hex)
    return table.find(MOBS, function(mob)
        return mob.hex == hex
    end)
end

local SPAWN_CHANCE = 50
function do_mob_spawning()
    --if WIN:key_pressed"space" then
    if math.random(SPAWN_CHANCE) == 1 then
        table.insert(MOBS, make_mob())
    end
end

function do_mob_updates()
    for i,mob in pairs(MOBS) do
        mob.update(mob, i)
    end
end

