local decodeInstruction = require('chip8.instruction-set')

local PROGRAM_START_ADDR = 0x200

local CYCLE_PERIOD = 1 / 500
local TICK_PERIOD = 1 / 60

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

local Chip8 = {}
Chip8.__index = Chip8

function Chip8.new(program)
    local self = {}
    setmetatable(self, Chip8)

    self:reset()

    if program then
        self:loadProgramBinary(program)
    end

    return self
end

function Chip8:reset()
    self.cycleCount = 0
    self.tickCount = 0

    self.waitingForKeyPress = nil

    self.stack = {}

    self.display = {}
    self:clearDisplay()

    self.width = WIDTH
    self.height = HEIGHT

    self.ip = PROGRAM_START_ADDR

    self.memory = {}

    self.V = {
        [0x0] = 0, [0x1] = 0, [0x2] = 0, [0x3] = 0,
        [0x4] = 0, [0x5] = 0, [0x6] = 0, [0x7] = 0,
        [0x8] = 0, [0x9] = 0, [0xA] = 0, [0xB] = 0,
        [0xC] = 0, [0xD] = 0, [0xE] = 0, [0xF] = 0,
    }

    self.I = 0

    self.DT = 0
    self.ST = 0

    self.K = {
        [0x0] = 0, [0x1] = 0, [0x2] = 0, [0x3] = 0,
        [0x4] = 0, [0x5] = 0, [0x6] = 0, [0x7] = 0,
        [0x8] = 0, [0x9] = 0, [0xA] = 0, [0xB] = 0,
        [0xC] = 0, [0xD] = 0, [0xE] = 0, [0xF] = 0,
    }
end

function Chip8:clearDisplay()
    for i = 0, (WIDTH * HEIGHT) do
        self.display[i] = 0
    end
end

function Chip8:update(dt)
    self.cycleCount = self.cycleCount + dt
    while self.cycleCount > CYCLE_PERIOD do
        self.cycleCount = self.cycleCount - CYCLE_PERIOD
        self:cycle()
    end

    self.tickCount = self.tickCount + dt
    while self.tickCount > TICK_PERIOD do
        self.tickCount = self.tickCount - TICK_PERIOD
        self:tick()
    end
end

function Chip8:tick()
    self.DT = math.max(0, self.DT - 1)
    self.ST = math.max(0, self.ST - 1)
end

-- one processor cycle, should be called with a frequency of 60Hz
function Chip8:cycle()
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

    -- process one instruction
    -- fetch
    local byte1 = self.memory[self.ip] or 0
    local byte2 = self.memory[self.ip + 1] or 0
    local word = byte1 * 16 * 16 + byte2
    local instruction = {
        raw  = word,

        _nnn = bit.band(word, 0x0fff),
        __kk = byte2,
        o___ = bit.rshift(bit.band(byte1, 0xf0), 4),
        _x__ = bit.band(byte1, 0x0f),
        __y_ = bit.rshift(bit.band(byte2, 0xf0), 4),
        ___n = bit.band(byte2, 0x0f),
    }

    -- decode
    decoded = decodeInstruction(instruction)

    -- execute
    decoded(self, instruction)
end

function Chip8:loadProgramBinary(program)
    local instructions = {}

    -- convert program code into a stream of words (2 bytes/16 bits)
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

function Chip8:loadProgram(instructions)
    self:reset()

    -- read instructions (stream of words) into memory as a stream of bytes
    -- first address for the program is at 0x200
    local p = PROGRAM_START_ADDR
    for _, inst in ipairs(instructions) do
        self.memory[p] = bit.rshift(inst, 8)
        self.memory[p + 1] = bit.band(inst, 0xff)
        p = p + 2
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

function Chip8:runCycles(numOfCycles)
    numOfCycles = numOfCycles or (#self.memory - PROGRAM_START_ADDR + 1)
    for i = 1, numOfCycles do
        self:cycle()
    end
end

return Chip8
