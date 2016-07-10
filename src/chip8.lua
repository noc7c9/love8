local bitops = require 'src.bitops'
local AND = bitops.AND
local RSHIFT = bitops.RSHIFT

local decodeInstruction = require('src.instruction-set')

local PROGRAM_START_ADDR = 0x200
local CLOCK_SPEED = 60

local WIDTH = 64
local HEIGHT = 32

local FONT_DATA = {
    {0xf0, 0x90, 0x90, 0x90, 0xf0}, -- 0
    {0x20, 0x60, 0x20, 0x20, 0x70}, -- 1
    {0xf0, 0x10, 0xf0, 0x80, 0xf0}, -- 2
    {0xf0, 0x10, 0xf0, 0x10, 0xf0}, -- 3
    {0x90, 0x90, 0xf0, 0x10, 0x10}, -- 4
    {0xf0, 0x80, 0xf0, 0x10, 0xf0}, -- 5
    {0xf0, 0x80, 0xf0, 0x90, 0xf0}, -- 6
    {0xf0, 0x10, 0x20, 0x40, 0x40}, -- 7
    {0xf0, 0x90, 0xf0, 0x90, 0xf0}, -- 8
    {0xf0, 0x90, 0xf0, 0x10, 0xf0}, -- 9
    {0xf0, 0x90, 0xf0, 0x90, 0x90}, -- A
    {0xe0, 0x90, 0xe0, 0x90, 0xe0}, -- B
    {0xf0, 0x80, 0x80, 0x80, 0xf0}, -- C
    {0xe0, 0x90, 0x90, 0x90, 0xe0}, -- D
    {0xf0, 0x80, 0xf0, 0x80, 0xf0}, -- E
    {0xf0, 0x80, 0xf0, 0x80, 0x80}, -- F
}

local chip8 = {}

function chip8.new(program)
    local clockPeriod = 1 / CLOCK_SPEED
    local clockTimer = 0

    local cpu = {}

    function cpu:reset()
        print('reset')

        clockTimer = 0

        cpu.stack = {}

        cpu.display = {}
        cpu:clearDisplay()

        cpu.width = WIDTH
        cpu.height = HEIGHT

        cpu.ip = PROGRAM_START_ADDR

        cpu.memory = {}

        cpu.V = {
            [0x0] = 0, [0x1] = 0, [0x2] = 0, [0x3] = 0,
            [0x4] = 0, [0x5] = 0, [0x6] = 0, [0x7] = 0,
            [0x8] = 0, [0x9] = 0, [0xA] = 0, [0xB] = 0,
            [0xC] = 0, [0xD] = 0, [0xE] = 0, [0xF] = 0,
        }

        cpu.I = 0

        cpu.DT = 0
        cpu.ST = 0

        cpu.K = {
            [0x0] = 0, [0x1] = 0, [0x2] = 0, [0x3] = 0,
            [0x4] = 0, [0x5] = 0, [0x6] = 0, [0x7] = 0,
            [0x8] = 0, [0x9] = 0, [0xA] = 0, [0xB] = 0,
            [0xC] = 0, [0xD] = 0, [0xE] = 0, [0xF] = 0,
        }

        cpu.waitingForKeyPress = nil
    end

    function cpu:clearDisplay()
        for i = 0, (WIDTH * HEIGHT) do
            cpu.display[i] = 0
        end
    end

    function cpu:displayIter()
    end

    function cpu:update(dt)
        clockTimer = clockTimer + dt
        while clockTimer > clockPeriod do
            clockTimer = clockTimer - clockPeriod
            self:cycle()
        end
    end

    function cpu:runCycles(numOfCycles)
        numOfCycles = numOfCycles or (#self.memory - PROGRAM_START_ADDR + 1)
        for i = 1, numOfCycles do
            self:cycle()
        end
    end

    -- one processor cycle, should be called with a frequency of 60Hz
    function cpu:cycle()
        -- wait for key press if necessary
        if self.waitingForKeyPress ~= nil then
            -- check if any key is pressed
            local key = nil
            for i = 0,0xf do
                if self.K[i] > 0 then
                    key = i
                    break
                end
            end

            -- continue if a key has been pressed
            if key ~= nil then
                self.V[self.waitingForKeyPress] = key
                self.waitingForKeyPress = nil
            else
                return
            end
        end

        -- decrement times
        self.DT = math.max(0, self.DT - 1)
        self.ST = math.max(0, self.ST - 1)

        -- process one instruction
        -- fetch
        local instruction = self.memory[self.ip] or 0
        instruction = {
            raw  = instruction,

            _nnn = AND(instruction, 0x0fff),
            __kk = AND(instruction, 0x00ff),
            o___ = RSHIFT(AND(instruction, 0xf000), 12),
            _x__ = RSHIFT(AND(instruction, 0x0f00), 8),
            __y_ = RSHIFT(AND(instruction, 0x00f0), 4),
            ___n = AND(instruction, 0x000f),
        }

        -- decode
        decoded = decodeInstruction(instruction)

        -- execute
        decoded(cpu, instruction)
    end

    function cpu:loadProgramBinary(program)
        local instructions = {}

        -- read program into memory as a stream of words (2 bytes/16 bits)
        -- first address for the program is at 0x200
        local i = 1
        local l = string.len(program)
        while (i < l) do
            local a, b = program:byte(i, i + 1)
            i = i + 2

            -- combine 2 bytes into a word
            table.insert(instructions, a * 16 * 16 + (b or 0))
        end

        self:loadProgram(instructions)
    end

    function cpu:loadProgram(instructions)
        self:reset()

        local p = PROGRAM_START_ADDR
        for _, inst in ipairs(instructions) do
            self.memory[p] = inst
            p = p + 1
        end

        -- set 0x000-0xfff in memory to zero
        for i = 0, (PROGRAM_START_ADDR-1) do
            self.memory[i] = 0
        end

        -- load font data into memory (from 0x000)
        for i, charData in ipairs(FONT_DATA) do
            i = i - 1
            for offset, byte in ipairs(charData) do
                self.memory[i * 5 + offset - 1] = byte
            end
        end
    end

    cpu:reset()

    if program then
        cpu:loadProgramBinary(program)
    end

    return cpu
end

return chip8
