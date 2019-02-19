# hex.lua

## INTRODUCTION [1.1]

this is a library for using hexagonal grids in amulet/lua.
it is extremely incomplete. the following list of features is 
either implemented shoddily, or not at all. 

if you want an actual good resource, go to [1.9].

## GETTING STARTED [1.2] 

//TODO

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
    
* storage system based on map shape - see chart:
   
| :SHAPE:           |                 :MAP STORAGE:                 | 
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

because so many different kinds of coordinate pairs, trios


## RESOURCES USED TO DEVELOP THIS LIBRARY, AND FOR WHICH I AM GRATEFUL [1.9] 
    
* [Hex Map 1](https://catlikecoding.com/unity/tutorials/hex-map/) - unity tutorial for hexagon grids with some useful generalized math.

* [3Blue1Brown - Essence of Linear Algebra](https://youtube.com/watch?v=fNk_zzaMoSs&list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab) - amazing series on linear algebra by 3Blue1Brown

* [Hexagonal Grids](https://redblobgames.com/grid/hexagons) - THE resource on hexagonal grids on the internet. 
    
* [Amulet Docs](http://amulet.xyz/doc) - amulet documentation.
  

