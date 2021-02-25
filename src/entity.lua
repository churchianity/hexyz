

--[[
entity structure:
{
    TOB             - number    - time of birth, const
    hex             - vec2      - current occupied hex, if any
    position        - vec2      - current pixel position of it's translate (forced parent) node
    update          - function  - runs every frame with itself and its index in some array as an argument
    node            - node      - scene graph node - should be initialized by caller after, though all entities have a node

    type            - enum      - sub type - unset if 'basic' entity
    props           - table     - table of properties specific to this entity subtype

    ...             - any       - a bunch of other shit depending on what entity type it is
}
--]]
function make_basic_entity(hex, update, position)
    local entity = {}

    entity.TOB = state.time

    -- usually you'll provide a hex and not a position, and the entity will spawn in the center
    -- of the hex. if you want an entity to exist not at the center of a hex, you can provide a
    -- pixel position instead, then the provided hex is ignored and instead we calculate what hex
    -- corresponds to the provided pixel position
    if position then
        entity.position = position
        entity.hex      = pixel_to_hex(entity.position, vec2(HEX_SIZE))
    else
        entity.hex      = hex
        entity.position = hex_to_pixel(hex, vec2(HEX_SIZE))
    end

    entity.update = update
    entity.node = false -- set by caller
    entity.type = false -- set by caller
    entity.props = {}

    return entity
end

function register_entity(t, entity)
    table.insert(t, entity)
    state.world:append(entity.node)
end

-- |t| is the source table, probably state.mobs, state.towers, or state.projectiles
function delete_entity(t, index)
    if not t then error("splat!") end

    state.world:remove(t[index].node)
    t[index] = false -- leave empty indexes so other entities can learn that this entity was deleted
end

function do_entity_updates()
    do_mob_updates()
    do_tower_updates()
    do_projectile_updates()
end

function entity_basic_devectored_copy(entity)
    local copy = table.shallow_copy(entity)
    copy.position = { copy.position.x, copy.position.y }
    copy.hex = { copy.hex.x, copy.hex.y }

    return copy
end

function entity_basic_json_parse(json_string)
    local entity = am.parse_json(json_string)
    entity.position = vec2(entity.position[1], entity.position[2])
    entity.hex = vec2(entity.hex[1], entity.hex[2])

    return entity
end

