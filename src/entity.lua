
--[[
entity structure:
{
    TOB             - number    - time of birth, const
    hex             - vec2      - current occupied hex, if any
    position        - vec2      - current pixel position of it's translate (forced parent) node
    update          - function  - runs every frame with itself and its index in some array as an argument
    node            - node      - scene graph node - should be initialized by caller after, though all entities have a node

    z               - number    - z-index of the scene node, what layer should this node be rendered at?
                                  we currently reserve z index 0 for just the 'floor', no towers or mobs or anything.
                                  most things will set this to 1 (or leave it unset, 1 is the default)
                                  we might use index -1 for underwater shit at some point

    type            - enum      - sub type
    props           - table     - table of properties specific to this entity subtype
}
--]]
function make_basic_entity(hex, update_f, position, z)
    local entity = {}

    entity.TOB = game_state.time

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

    entity.update = update_f
    entity.z = z or 1
    entity.props = {}

    return entity
end

function register_entity(t, entity)
    table.insert(t, entity)

    game_state.world(world_layer_tag(entity.z)):append(entity.node)
end

-- |t| is the source table, probably game_state.mobs, game_state.towers, or game_state.projectiles
function delete_entity(t, index)
    if not t then error("splat!") end

    local entity = t[index]
    game_state.world(world_layer_tag(entity.z)):remove(entity.node)
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

function init_entity_specs()
    init_tower_specs()
end

