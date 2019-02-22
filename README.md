
## INTRODUCTION

this is a library for using hexagonal grids in amulet/lua.
it is extremely incomplete. the following list of features is 
either implemented shoddily, or not at all. 

if you want an actual good resource, go to TODO LINK.

## GETTING STARTED

1) initialize a map.
2) iterate over the map and draw some hexagons. 

## COORDINATE SYSTEMS
    
As much coordinate manipulation as possible is done internally.
Depending on the task, uses either Axial, Cube, or Offset coordinates.

## MAPS & MAP STORAGE
    
Some map shapes: parallelogram, rectangular, hexagonal, triangular. (and more)
The storage system used is based on the map shape - see chart:
   
|       SHAPE       |                  MAP STORAGE                  | 
| ----------------- | --------------------------------------------- |
| parallelogram     |   unordered, hash-like                        |   
| rectangular       |   unordered, hash-like                        |   
| hexagonal         |   unordered, hash-like                        |   
| triangular        |   unordered, hash-like                        |   
| ring              |   ordered, array-like                         |   
| spiral            |   ordered, array-like                         |      
| arbitrary         |   unordered, hash-like                        |   
    
    * note that a spiral map is just a hexagonal one with a particular order.

By default, the unordered, hash-like maps have pseudo-random noise stored 
as their values. This can be useful for a whole bunch of things, but if you 
wish, you can simply iterate over your map and set every value to 'true'. 

## CONVENTIONS AND TERMINOLOGY

If you have read amit's guide to hexagon grids, (see TODO LINK), a lot of the 
terminology will be familiar to you - I utilize many conventions he does in
his guide. That being said...

Because so many similar kinds of data structures with different goals are used 
in this library it can be hard to remember precisely what they all refer to. 

The following table shows what each table/vector/array refers to in the code:

| NAME |                       REFERS TO                              |  
| ---- | ------------------------------------------------------------ |
| cube | xyz, *vector* used for most maps, with constraint x+y+z=0.   |
| pix  | xy, *vector* true screen pixel coordinates                   |
| off  | xy, 'offset', *vector* used for UI implementations           |
| map  | xy, *table* of unit hexagon centerpoints arranged in a shape |

    * note that 'axial', vec2() coordinates are a subset of cube coordinates, 
    where you simply omit the z value. for many algorithms this is done, but 
    instead of using a seperate reference name 'axial' in these cases, I used 
    the name 'cube' for both. I found this to be simpler. when an algorithm 
    asks for a cube, give it a cube. if you want to know if it works with axial
    as well, look at the code and see if it uses a 'z' value.

Other terminology:   

* TODO

## RESOURCES USED TO DEVELOP THIS LIBRARY, AND FOR WHICH I AM GRATEFUL 
    
* [Hex Map 1](https://catlikecoding.com/unity/tutorials/hex-map/) - unity tutorial for hexagon grids with some useful generalized math.

* [3Blue1Brown - Essence of Linear Algebra](https://youtube.com/watch?v=fNk_zzaMoSs&list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab) - amazing series on linear algebra by 3Blue1Brown

* [Hexagonal Grids](https://redblobgames.com/grid/hexagons) - THE resource on hexagonal grids on the internet. 
    
* [Amulet Docs](http://amulet.xyz/doc) - amulet documentation.
  

