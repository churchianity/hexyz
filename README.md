
## INTRODUCTION

This is a small and simple library for using hexagonal grids in amulet + lua. I wrote it for a tower defense game I'm making.

It's not really well documented. If you want an actual good resource, go to [amit's guide to hexagonal grids](https://redblobgames.com/grid/hexagons).
So much of what is here I derived from amit's work.


## CONVENTIONS & TERMINOLOGY

If you have read amit's guide to hexagon grid, a lot of the terminology will be familiar to you - I utilize many conventions he does in his guide. That being said,
because so many similar kinds of data structures with different goals are used in this library it can be hard to remember precisely what they all refer to.
The following table shows what each table/vector/array refers to in the code:

| NAME |                       REFERS TO                              |
| ---- | ------------------------------------------------------------ |
| hex  | xyz, *vector* used for most tasks, with constraint x+y+z=0   |
| pix  | xy, *vector* true screen pixel coordinates                   |
| off  | xy, 'offset', *vector* used for UI implementations           |
| map  | xy, *table* of unit hexagon centerpoints arranged in a shape |

    * note that 'hex' here is a catch-all term for cube/axial, as they can often be used interchangeably.


## MAPS & MAP STORAGE

The storage system used is based on the map shape - see chart:

|     SHAPE     |      STORAGE TYPE      |     KEY      |     VALUE     |
| ------------- | ---------------------- | ------------ | ------------- |
| ring          |  ordered, array-like   |    index     |   vec2(i, j)  |
| spiral        |  ordered, array-like   |    index     |   vec2(i, j)  |
| parallelogram |  unordered, hash-like  |  vec2(i, j)  | simplex noise |
| rectangular   |  unordered, hash-like  |  vec2(i, j)  | simplex noise |
| hexagonal     |  unordered, hash-like  |  vec2(i, j)  | simplex noise |
| triangular    |  unordered, hash-like  |  vec2(i, j)  | simplex noise |

    * note that a spiral map is just a hexagonal one with a particular order.

The noise values on the hashmaps are seeded. You can optionally provide a seed after the map's dimensions as an argument, otherwise it's a random seed.


## RESOURCES

* [Hex Map 1](https://catlikecoding.com/unity/tutorials/hex-map/) - unity tutorial for hexagon grids with some useful generalized math.

* [Hexagonal Grids](https://redblobgames.com/grid/hexagons) - THE resource on hexagonal grids on the internet.

* [Amulet Docs](http://amulet.xyz/doc) - amulet documentation.

