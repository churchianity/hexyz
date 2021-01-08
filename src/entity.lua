

ENTITY_TYPE = {
    ENTITY     = 0,
    MOB        = 1,
    TOWER      = 2,
    PROJECTILE = 3
}

ENTITIES = {}
--  entity structure:
--  {
--      TOB             - number    - time of birth, const
--      hex             - vec2      - current occupied hex, if any
--      position        - vec2      - current pixel position of it's translate (forced parent) node
--      update          - function  - runs every frame with itself and its index as an argument
--      node            - node      - scene graph node
--  }
--
--  mob(entity) structure:
--  {
--      path            - 2d table  - map of hexes to other hexes, forms a path
--      speed           - number    - multiplier on distance travelled per frame, up to the update function to use correctly
--      bounty          - number    - score bonus you get when this mob is killed
--      hurtbox_radius  - number    -
--  }
--
--  tower(entity) structure:
--  {
--      -- @NOTE these should probably be wrapped in a 'weapon' struct or something, so towers can have multiple weapons
--      range           - number    - distance it can shoot
--      last_shot_time  - number    - timestamp (seconds) of last time it shot
--      target_index    - number    - index of entity it is currently shooting
--  }
--
--  bullet/projectile structure
--  {
--      vector          - vec2      - normalized vector of the current direction of this projectile
--      velocity        - number    - multplier on distance travelled per frame
--      damage          - number    - guess
--      hitbox_radius   - number    - hitboxes are circles
--  }
--
function make_and_register_entity(type_, hex, node, update)
    local entity = {}

    entity.type     = type_
    entity.TOB      = TIME
    entity.hex      = hex
    entity.position = hex_to_pixel(hex)
    entity.update   = update or function() log("unimplemented update function!") end
    entity.node     = am.translate(entity.position) ^ node

    table.insert(ENTITIES, entity)
    WORLD:append(entity.node)
    return entity
end

function delete_all_entities()
    for index,entity in pairs(ENTITIES) do
        delete_entity(index)
    end

    ENTITIES = {}
end

function delete_entity(index)
    WORLD:remove(ENTITIES[index].node)
    ENTITIES[index] = nil -- leave empty indexes so other entities can learn that this entity was deleted
end

function do_entity_updates()
    for index,entity in pairs(ENTITIES) do
        entity.update(entity, index)
    end
end

