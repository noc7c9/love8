[![Love8](https://github.com/noc7c9/love8/blob/master/logo.png "Love8")](https://github.com/noc7c9/love8)

# Love8

[Chip-8](https://en.wikipedia.org/wiki/CHIP-8) emulator implemented using
[Lua](https://www.lua.org/) and the [Love2D](https://love2d.org/) game engine.

## Running

The project can be run like any other Love2D game.
It is meant to run on version 11.2 but will most likely run perfectly fine on
previous versions.

The easiest way is to run the following commands:

```sh
$ cd love8
$ love .
```

### Loading ROMs

Once the emulator is running, the default demo rom will be loaded. Other roms
can be loaded by dropping the rom file onto the emulator window.

It is also possible to load roms when starting by passing it as an argument.

```sh
$ cd love8
$ love . path/to/rom.ch8
```

Note: All roms are subject to the Love2D filesystem [lockdown
limits](https://love2d.org/wiki/love.filesystem). Just put them in the emulator
directory and they should load correctly.

### Running Tests

The tests are intended to be run in the Love2D environment. Simply pass the
`--tests` flag. The Love2D window should pop up and immediately close, and the
test results should be logged to the terminal.

```sh
$ cd love8
$ love . --tests
...
34 tests passed!
```

## Thanks

This project could not have been possible without the following resources & projects:

- [Cowgod's Chip-8 Technical Reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM)
- [How to write an emulator (CHIP-8 interpreter)](http://www.multigesture.net/articles/how-to-write-an-emulator-chip-8-interpreter/)
- [JohnEarnest/Octo](https://github.com/JohnEarnest/Octo)
- [AfBu/haxe-chip-8-emulator](https://github.com/AfBu/haxe-chip-8-emulator)
- [adrianton3/chip8](https://github.com/adrianton3/chip8)
