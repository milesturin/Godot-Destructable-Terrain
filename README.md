# Godot-Destructable-Terrain

A 2d destructible terrain system for the open source game engine [Godot](https://github.com/godotengine/godot). Its contour generation is based off of the interpolated variant of the [Marching Squares](https://en.wikipedia.org/wiki/Marching_squares) algorithm. It supports collision detection, as illustrated by the colored triangles. It utilizes a chunking system which allows for loading and unloading of chunks as well as faster mesh regeneration after terrain modifications. Even extreme cases of terrain creation and destruction run at acceptable speeds, and there is room for vast optimization. 

![Terrain Demo](/terrain_demo.gif)

A rudimentary platformer controller is included to demonstrate potential uses of the library.

![Player Demo](/player_demo.gif)

The source code can be found [here](https://github.com/milesturin/Godot-Destructable-Terrain/tree/main/src/scripts).
