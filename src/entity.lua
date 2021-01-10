

MOBS = {}
TOWERS = {}
PROJECTILES = {}

--[[
entity structure:
{
    TOB             - number    - time of birth, const
    hex             - vec2      - current occupied hex, if any
    position        - vec2      - current pixel position of it's translate (forced parent) node
    update          - function  - runs every frame with itself and its index as an argument
    node            - node      - scene graph node
}
--]]
function make_basic_entity(hex, node, update, position)
    local entity = {}

    entity.TOB      = TIME

    -- usually you'll provide a hex and not a position, and the entity will spawn in the center
    -- of the hex. if you want an entity to exist not at the center of a hex, you can provide a
    -- pixel position instead
    if position then
        entity.position = position
        entity.hex      = pixel_to_hex(entity.position)
    else
        entity.hex      = hex
        entity.position = hex_to_pixel(hex)
    end

    entity.update   = update
    entity.node     = am.translate(entity.position) ^ node

    return entity
end

function register_entity(t, entity)
    table.insert(t, entity)
    WORLD:append(entity.node)
end

-- |t| is the source table, probably MOBS, TOWERS, or PROJECTILES
function delete_entity(t, index)
    if not t then log("splat!") end

    WORLD:remove(t[index].node)
    t[index] = false -- leave empty indexes so other entities can learn that this entity was deleted
end

function delete_all_entities()
    for mob_index,mob in pairs(MOBS) do
        delete_entity(MOBS, mob_index)
    end
    for tower_index,tower in pairs(TOWERS) do
        delete_entity(TOWERS, tower_index)
    end
    for projectile_index,projectile in pairs(PROJECTILES) do
        delete_entity(PROJECTILES, projectile_index)
    end
end

function do_entity_updates()
    for mob_index,mob in pairs(MOBS) do
        if mob and mob.update then
            mob.update(mob, mob_index)
        end
    end
    for tower_index,tower in pairs(TOWERS) do
        if tower and tower.update then
            tower.update(tower, tower_index)
        end
    end
    for projectile_index,projectile in pairs(PROJECTILES) do
        if projectile and projectile.update then
            projectile.update(projectile, projectile_index)
        end
    end
end

