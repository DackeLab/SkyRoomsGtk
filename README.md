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

### `from_file()`
This function loads a [`.toml` file](https://toml.io/en/), where all the setups are predefined. To see an example of such a file look [here](examples/example.toml). It then opens a window with as many buttons as there are setups in that `.toml` file. Each setup is assigned a letter on your keyboard, so pressing `a` loads up the first setup, pressing `b` loads up the second, etc. Each button shows the name of its corresponding setup, but also the keyboard letter assigned to it. 

It will pick the first `.toml` file it finds in the user's home-directory (run `homedir()` in a Julia terminal to see where your home-directory is). To use a specific `.toml` file, call the function with the path to your file. For example, if the path to your file is `/home/john/things/myfile.toml` then call `from_file("/home/john/things/myfile.toml")` (note the quotation marks). 

## Notes
- There can only be a maximum of 80 suns.
- There can only be a maximum of 26 (the number of alphabets) setups in the `.toml` file.
- A table showing the relationship between the integer LED elevation (i.e. 1-71) and its real elevation in degrees (i.e. 0°-90°) can be found [here](mk_tbls/elevations.md).
- A table showing the relationship between the fan's duty in percent (i.e. 0%-100%) and its real RPMs can be found [here](mk_tbls/rpms.md).
- To edit your `.toml` file use a text editor (e.g. Notepad, TextEdit, Gedit, Vim, etc...), *not* a word processor (e.g. Word, Google Docs, LibreOffice, etc...).

# Field setup
The field setup includes:
1. USB-B cable
2. Four black boxes (`A`, `B`, `C`, and `D`)
3. Two LED strips (`AB` and `CD` )
4. (at least) two 5 VDC power adapters
5. A MacBook Air
6. A power adapter for the laptop

Connect the `A` end of the `AB` LED strip to black box `A`

![Black box A](docs/A.jpg?raw=true "Black box A")

and the `B` end to black box `B`.

![Black box B](docs/B.jpg?raw=true "Black box B")

Connect the `C` end of the `CD` LED strip to black box `C`

![Black box C](docs/C.jpg?raw=true "Black box C")

and the `D` end to black box `D`.

![Black box D](docs/D.jpg?raw=true "Black box D")

Connect one power adapter to each of the black boxes `A`, `B`, `C`, and `D`. 

![overview](docs/overview.jpg?raw=true "overview")

Finally, connect your computer to black Box `A` with the USB-B cable

![USB](docs/USB.jpg?raw=true "USB")

and follow the instructions in [the How section](#how). 

The strips should be mounted onto the aluminum arches in the following way:
1. The `A` end of the `AB` strip should have its 1st LED as close to the ground as possible: this 1st LED will be at elevation 0°.
2. Once the `AB` strip is fully mounted/glued to the arch, the `B` end of the `AB` strip should have 9 "unused" LEDs. There are 150 LEDs in the `AB` strip, the 141st LED will be close to the ground at elevation 0°. As a result, the 71st LED will be at zenith, elevation 90°.
3. The `C` end of the `CD` strip should have its 1st LED as close to the ground as possible.
4. Once the `CD` strip is fully mounted/glued to the arch, the `D` end of the `CD` strip should have only 7 "unused" LEDs. There are only 148 LEDs in the `CD` strip.
5. For clearer nomenclature, you should orient the arches such that the `A` end of the `AB` strip is pointing North East (NE), `B` pointing SW, `C` pointing SE, and `D` NW.
6. It stands to reason that black box `A` should be closest to the laptop, and therefore the laptop should be NE to the center of the arena.

## Notes
- If you intend to have many suns and/or large radii, add 2 more power adapters by plugging each additional adapter to black box `B` and `C`. This will ensure that the brightness and/or color of the suns won't change as a function of elevation.
- The additional power socket in black boxes `A` and `D` are identical (each box has 2 power sockets). There is no need to prefer one over the other. 
- The clamps can be used to gently clamp down on the LED strip so to avoid any strain on the connection between the strip and the electric wires. You don't have to use these unless you feel the strips are repeatedly being pulled on by some force (try to avoid that altogether).

![clamp](docs/clamp.jpg?raw=true "clamp")

