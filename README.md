
## INTRODUCTION [1.1]

this is a library for using hexagonal grids in amulet/lua.
it is extremely incomplete. the following list of features is 
either implemented shoddily, or not at all. 

if you want an actual good resource, go to [1.9].

## GETTING STARTED [1.2] 

* TODO

## COORDINATE SYSTEMS [1.3]
    
as much coordinate manipulation as possible is done internally.
depending on the task, uses either Axial, Cube, or Doubled coordinates.

three different ways of returning and sending coordinates:
    
* amulet vectors
* lua tables
* individual coordinate numbers
    
so you can use what your graphics library likes best!

## MAPS & MAP STORAGE [1.4]
    
Some map shapes: parallelogram, rectangular, hexagonal, triangular. (and more)
    
The storage system used is based on the map shape - see chart:
   
|       SHAPE       |                  MAP STORAGE                  | 
| ----------------- | --------------------------------------------- |
| parallelogram     |   unordered, hash-like OR ordered, array-like |   
| rectangular       |   unordered, hash-like OR ordered, array-like |   
| hexagonal         |   unordered, hash-like OR ordered, array-like |   
| triangular        |   unordered, hash-like OR ordered, array-like |   
| ring              |   ordered, array-like                         |   
| spiral            |   ordered, array-like**                       |      
| arbitrary         |   unordered, hash-like                        |   
    
    ** note that a spiral map is just a hexagonal one with a particular order.

## CONVENTIONS AND TERMINOLOGY [1.8] 

If you have read amit's guide to hexagon grids, (see [1.9]), a lot of the 
terminology will be familiar to you - I utilize many conventions he does in
his guide. That being said...

Because so many different kinds of coordinate groupings are used in this library,
and they are all fundamentally tables/vectors/arrays of integers, it can be hard
to remember what they are all referring to. 

The following table shows what each table/vector/array refers to in the code:

| NAME |                       REFERS TO                            |  
| ---- | ---------------------------------------------------------- |
| cube | xyz, used for most maps, with constraint x+y+z=0. **       |
| pix  | xy, true screen pixel coordinates                          |
| dbl  | xy, 'doubled', used for rectangular maps                   |
| off  | xy, 'offset', used for UI implementations                  |
| ---- | ---------------------------------------------------------- |
| map  | xy, table of unit hexagon centerpoints arranged in a shape |

    ** note that 'axial' coordinates are a subset of cube coordinates, where
    you simply omit the z value. for many algorithms this is done, but instead
    of using some reference name 'axial', I just used the name 'cube' for both 
    cases. I found this to be clearer and less prone to end-user error. when
    an algorithm asks for a cube, give it a cube. if you want to know if it works
    with axial as well, look at the code and see if it uses a 'z' value.

Other terminology:   

* TODO

## RESOURCES USED TO DEVELOP THIS LIBRARY, AND FOR WHICH I AM GRATEFUL [1.9] 
    
* [Hex Map 1](https://catlikecoding.com/unity/tutorials/hex-map/) - unity tutorial for hexagon grids with some useful generalized math.

* [3Blue1Brown - Essence of Linear Algebra](https://youtube.com/watch?v=fNk_zzaMoSs&list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab) - amazing series on linear algebra by 3Blue1Brown

* [Hexagonal Grids](https://redblobgames.com/grid/hexagons) - THE resource on hexagonal grids on the internet. 
    
* [Amulet Docs](http://amulet.xyz/doc) - amulet documentation.
  

