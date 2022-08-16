# SkyRoomsGtk

## What

A [Julia](https://julialang.org/) package to control the skyrooms, Sheldon and Nicolas, in the Biology building at Lund University.

## How

You need to do these only once:
1. [Download and install Julia](https://julialang.org/downloads/)
2. Install this package:
```
import(Pkg)
Pkg.add(url="https://github.com/yakir12/SkyRoomsGtk")
```

Once you start a Julia session (a Julia terminal, REPL, will open), you need to do this only once per Julia session:
1. Load the package:
```julia
using SkyRoomsGtk
```
Connect the USB cable connected to the LED strip (in Sheldon) or USB-hub (in Nicolas) to your computer.

There are two main ways to control the skyrooms with this package:
1. `gui()`: An interactive [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) that allows the user to controls the suns and fans. Better suited for testing purposes. 
2. `from_file()`: A way to switch between predefined setups. Better suited for running experiments.

### `gui()`
Opens a window with 4 "suns" and as many fan-groups as there are connected (relevant only to Nicolas). You can control each sun's cardinality, elevation, radius, red, green, and blue intensities, as well as the duty of each fan-group. To have more (or less) than 4 suns call this function with the number of suns you want (e.g. `gui(7)` for 7 suns). 

### `from_file()
This function loads a [`.toml` file](https://toml.io/en/), where all the setups are predefined. To see an example of such a file look [here](examples/example.toml). It then opens a window with as many buttons as there are setups in that `.toml` file. Each setup is assigned a letter on your keyboard, so pressing `a` loads up the first setup, pressing `b` loads up the second, etc. Each button shows the name of its corresponding setup, but also the keyboard letter assigned to it. 

It will pick the first `.toml` file it finds in the user's home-directory (run `homedir()` in a Julia terminal to see where your home-directory is). To use a specific `.toml` file, call the function with the path to your file. For example, if the path to your file is `/home/john/things/myfile.toml` then call `from_file("/home/john/things/myfile.toml")` (note the quotation marks). 

## Notes
There can only be a maximum of 80 suns.
There can only be a maximum of 26 (the number of alphabets) setups in the `.toml` file.
