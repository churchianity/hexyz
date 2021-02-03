

--[[
entity structure:
{
    TOB             - number    - time of birth, const
    hex             - vec2      - current occupied hex, if any
    position        - vec2      - current pixel position of it's translate (forced parent) node
    update          - function  - runs every frame with itself and its index in some array as an argument
    node            - node      - scene graph node

    ...             - any       - a bunch of other shit depending on what entity type it is
}
--]]
function make_basic_entity(hex, node, update, position)
    local entity = {}

    entity.TOB = state.time

    -- usually you'll provide a hex and not a position, and the entity will spawn in the center
    -- of the hex. if you want an entity to exist not at the center of a hex, you can provide a
    -- pixel position instead, then the provided hex is ignored and instead we calculate what hex
    -- corresponds to the provided pixel position
    if position then
        entity.position = position
        entity.hex      = pixel_to_hex(entity.position)
    else
        entity.hex      = hex
        entity.position = hex_to_pixel(hex)
    end

    entity.update = update
    entity.node = am.translate(entity.position) ^ node

    return entity
end

function register_entity(t, entity)
    table.insert(t, entity)
    state.world:append(entity.node)
end

-- |t| is the source table, probably MOBS, TOWERS, or PROJECTILES
function delete_entity(t, index)
    if not t then log("splat!") end

    WORLD:remove(t[index].node)
    t[index] = false -- leave empty indexes so other entities can learn that this entity was deleted
end

function delete_all_entities()
    delete_all_mobs()
    delete_all_towers()
    delete_all_projetiles()
end

function do_entity_updates()
    do_mob_updates()
    do_tower_updates()
    do_projectile_updates()
end

