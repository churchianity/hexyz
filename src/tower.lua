
local TOWERS = {}
--[[
    tower structure:
    {
        TOB         - float     -- time stamp in seconds of when the tower was spawned
        hex         - vec2      -- hexagon the tower is on
        position    - vec2      -- true pixel coordinates
        node        - node      -- the root graph node for this tower
        update      - function  -- function that gets called every frame with itself as an argument
    }
]]

function is_buildable(hex, tile, tower)
    local blocked = mob_on_hex(hex)
    return not blocked and is_passable(tile)
end

function make_tower(hex)
    local tower = {}

    tower.TOB           = TIME
    tower.hex           = hex
    tower.position      = hex_to_pixel(tower.hex)
    tower.node          = am.translate(tower.position)
                          ^ pack_texture_into_sprite(TEX_TOWER1, 55, 55)

    tower.update        = function(_tower) end

    -- make this cell impassable
    --HEX_MAP.get(hex.x, hex.y).elevation = 2

    WIN.scene"world":append(tower.node)

    return tower
end

function do_tower_updates()
    for i,tower in pairs(TOWERS) do
        tower.update(tower, i)
    end
end

