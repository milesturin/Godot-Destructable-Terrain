# Godot-Destructable-Terrain

A 2d destructible terrain system I built for the open source game engine [Godot](https://github.com/godotengine/godot). Its contour generation is based off of the interpolated variant of the [Marching Squares](https://en.wikipedia.org/wiki/Marching_squares) algorithm. It supports collision detection, as illustrated by the colored triangles. It utilizes a chunking system which allows loading and unloading of chunks as well as faster mesh regeneration after terrain modifications. Even extreme cases of terrain creation and destruction already run at acceptable speeds, but there is room for vast optimization once necessary. 

![Terrain Demo](/terrain_demo.gif)

A rudimentary platformer controller is included to demonstrate creative potential.

![Player Demo](/player_demo.gif)

The source code can be found [here](https://github.com/milesturin/stronghold/tree/master/src/scripts).
