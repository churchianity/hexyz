

todoooos & notes

@TODO test optimizing pathfinding via breadth first search/djikstra

i think i want more or less no such thing as 'impassable' terrain

all mobs always can always traverse everything, though they initially will give the impression that certain tiles are impassable by prefering certain tiles.

the illusion is likely to be broken when you attempt to fully wall-off an area, and mobs begin deciding to climb over mountains or swim through lakes. this will come at great cost to them, but they will be capable of it

MAP RESOURCES
- spawn diamonds or special floating resources that give you bonuses for building on, whether it's score, money, or boosting the effectiveness of the tower you place on top, etc.
- killing certain mobs may cause these resources to spawn on the hex they died on


towers:
0 - wall
    some fraction of the height of the tallest mountain
    makes mob pathing more difficult

    upgrades:
        - +height - making the tower taller makes it more difficult/costly for mobs to climb over it
        - spikes  - mobs take damage when climbing

1 - moat
    some fraction of the depth of the deepest lake
    makes mob pathing more difficult

    upgrades:
        - +depth - making the moat deeper makes it more difficult/costly for mobs to swim through it
        - alligators - mobs take damage while swimming


