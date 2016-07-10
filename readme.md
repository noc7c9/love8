- chip8 interpretor using the love2d framework

# roadmap

- allow viewing the interpreter's internal state on the screen
    - memory
        - scrollable
            - starts scrolled so that the first 0x1FF addresses are skipped
                - the first 0x1FF are displayed in red anyway
            - for simplicity don't bother with clipping and just let it scroll
              off the edge
    - input
        - live display of keypad
            - actual faux buttons that get highlighted when the real button is pressed
    - display
        - the raw data as ones and zeros

- implement all the instructions
    - test-driven style
    - checklist
        - 00E0 - CLS
        - Dxyn - DRW Vx, Vy, nibble

- make sure all asm cmds in the tests use 0x to prefix numbers

- move debug display to its own file

- restructure project into subprojects, each with its own folder
    - ./src/chip8 - chip8 interpretor implementation in lua independant of love2d
    - ./src/love8 - love2d ui for chip8
    - ./src/term8 - terminal ui for chip8
    - ./main.lua, used by love2d or if run directly runs the term8 terminal ui
    - ./test.lua, runs tests

- decouple the sound/delay timers and the instruction cycle
    - the sound/delay timers tick down at 60 Hz
        - called ticks
    - the instruction cycle has a rate of 600 Hz
        - called [instruction] cycles
        - 10 cycles per 60 Hz

- rewrite the opcode decode code to be more cleaner and more elegant

# features

- my own assembler and disassembler in lua
    - the disassembler is used in the debug display, to display cmds next to
      the opcodes
    - assembler is used in the testing environment

- ability to speed up/slow down the emulator

- configurable input keymappings

- chip8, schip and megachip support

# resources

- http://www.codeslinger.co.uk/pages/projects/chip8.html

- blog.alexanderdickson.com/javascript-chip-8-emulator

- http://devernay.free.fr/hacks/chip8/C8TECH10.HTM

- https://en.wikipedia.org/wiki/CHIP-8

- https://mir3z.github.io/chip8-emu/doc/

- http://www.pong-story.com/chip8/
