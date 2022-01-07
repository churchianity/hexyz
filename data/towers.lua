--[[
    the following is a list of tower specifications, which are declarations of a variety of properties describing what a tower is, and how it functions
    this a lua file. a quick run-down of what writing code in lua looks like: https://www.amulet.xyz/doc/#lua-primer

    each tower spec is a lua table. lua tables are the thing that you use to represent bundles of data (both arrays and hashtables are represented by tables)

    the format of the bundles in our case are described below.
    some propreties are optional. required properties are marked with an asterisk (*), and are generally included at the top of the list.

    # TOWER SPEC TABLE
    | --------------------------| -------- | -------------------------------------------------------------- |
    | property name, required*  | datatype | general description / details                                  |
    | --------------------------| -------- | -------------------------------------------------------------- |
    | name*                     | string   | exact one-line display name text of the tower                  |
    | placement_rules_text*     | string   | one-line description of the placement rules for this tower     |
    | short_description*        | string   | one-line description of the nature of this tower               |
    | texture*                  | userdata | @TODO                                                          |
    | icon_texture*             | userdata | @TODO                                                          |
    | cost*                     | number   | the starting cost of placing this tower                        |
    |                           |          |                                                                |
    | weapons*                  | table    | an array of weapons.                                           |
    |                           |          | order matters - two weapons share a 'choke' value, and both    |
    |                           |          | could acquire a target in a frame, the first one is choosen.   |
    |                           |          |                                                                |
    | placement_f               | function |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    |                           |          |                                                                |
    | visual_range              | number   | when the tower has multiple weapons, what range represents the |
    |                           |          | overall range of the tower. default is calculated on load as   |
    |                           |          | the largest range among the weapons the tower has.             |
    | min_visual_range          | number   | same as above but the largest minimum range among weapons      |
    |                           |          |                                                                |
    | update_f                  | function | default value is complicated @TODO                             |
    | grow_f                    | function | default value is false/nil. @TODO                              |
    | size                      | number   | default value of 1, which means the tower occupies one hex.    |
    | height                    | number   | default value of 1. height is relevant for mob pathing and     |
    |                           |          | projectile collision                                           |
    |                           |          |                                                                |
    | --------------------------| -------- | -------------------------------------------------------------- |

    # WEAPON TABLE
    | --------------------------| -------- | -------------------------------------------------------------- |
    | property name, required*  | datatype | general description / details                                  |
    | --------------------------| -------- | -------------------------------------------------------------- |
    | type                      | number   | sometimes, instead of specifying everything for a weapon, it's |
    |                           |          | convenient to refer to a base type. if this is provided all of |
    |                           |          | the weapon's other fields will be initialized to preset values |
    |                           |          | and any other values you provide with the weapon spec will     |
    |                           |          | overwrite those preset values.                                 |
    |                           |          | if you provide a value here, all other properties become       |
    |                           |          | optional.                                                      |
    |                           |          | values you can provide, and what they mean:                    |
    |                           |          |   @TODO                                                        |
    |                           |          |                                                                |
    | fire_rate*                | number   | 'shots' per second, if the weapon has a valid target           |
    | range*                    | number   | max distance (in hexes) at which this weapon acquires targets  |
    |                           |          |                                                                |
    | min-range                 | number   | default of 0. min distance (in hexes) at which this weapon acquires targets  |
    | target_acquisition_f      | function | default value is complicated @TODO                             |
    | choke                     | number   | default of false/nil. @TODO                                    |
    |                           |          |                                                                |
    | --------------------------| -------- | -------------------------------------------------------------- |
]]
