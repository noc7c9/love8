local chip8 = require 'src.chip8'
local dec2hex = require('src.helpers').dec2hex

local displayInternalState = false

local function drawMemory(ox, oy)
    local print = love.graphics.print
    local color = love.graphics.setColor

    local mem = chip8.memory
    local ip = chip8.ip

    local function drawInst(index, x, y)
        if ip == index then
            color(0, 255, 0)
        end
        if mem[index] then
            print(dec2hex(mem[index]), x, y)
        end
        if ip == index then
            color(255, 255, 255)
        end
    end

    local x, y = ox, oy - (14 * 0x200 / 4) -- start with the first 0xff bytes not visible
    local i = 0
    local l = #mem
    while i <= l do
        print('0x' .. dec2hex(i, 3) .. ':', x, y)

        drawInst(i + 0, x + 50 + 36 * 0, y)
        drawInst(i + 1, x + 50 + 36 * 1, y)
        drawInst(i + 2, x + 50 + 36 * 2, y)
        drawInst(i + 3, x + 50 + 36 * 3, y)

        y = y + 14
        i = i + 4
    end

    return 50 + 36 * 4, y - ox
end

local function drawRegisters(ox, oy)
    local print = love.graphics.print

    local x, y = ox, oy

    print("Registers:", x, y)

    y = y + 14 + 4
    print("v0=" .. dec2hex(chip8.V[0x0], 2), x + 46 * 0, y)
    print("v1=" .. dec2hex(chip8.V[0x1], 2), x + 46 * 1, y)
    print("v2=" .. dec2hex(chip8.V[0x2], 2), x + 46 * 2, y)
    print("v3=" .. dec2hex(chip8.V[0x3], 2), x + 46 * 3, y)
    y = y + 14
    print("v4=" .. dec2hex(chip8.V[0x4], 2), x + 46 * 0, y)
    print("v5=" .. dec2hex(chip8.V[0x5], 2), x + 46 * 1, y)
    print("v6=" .. dec2hex(chip8.V[0x6], 2), x + 46 * 2, y)
    print("v7=" .. dec2hex(chip8.V[0x7], 2), x + 46 * 3, y)
    y = y + 14
    print("v8=" .. dec2hex(chip8.V[0x8], 2), x + 46 * 0, y)
    print("v9=" .. dec2hex(chip8.V[0x9], 2), x + 46 * 1, y)
    print("vA=" .. dec2hex(chip8.V[0xA], 2), x + 46 * 2, y)
    print("vB=" .. dec2hex(chip8.V[0xB], 2), x + 46 * 3, y)
    y = y + 14
    print("vC=" .. dec2hex(chip8.V[0xC], 2), x + 46 * 0, y)
    print("vD=" .. dec2hex(chip8.V[0xD], 2), x + 46 * 1, y)
    print("vE=" .. dec2hex(chip8.V[0xE], 2), x + 46 * 2, y)
    print("vF=" .. dec2hex(chip8.V[0xF], 2), x + 46 * 3, y)

    y = y + 14 + 4
    print("I=" .. dec2hex(chip8.I, 3), x, y)

    return 46 * 4, y - oy + 14
end

local function drawStack(ox, oy)
    local print = love.graphics.print

    local stack = chip8.stack

    local function drawAddr(addr, x, y)
        if addr then
            print(dec2hex(addr, 3), x, y)
        end
    end

    local x, y = ox, oy

    print("Stack: [Size=" .. #stack .. "]", x, y)
    local y = y + 14 + 4

    local i = 1
    local l = #stack
    while i < l do
        drawAddr(stack[i + 0], x + 30 * 0, y)
        drawAddr(stack[i + 1], x + 30 * 1, y)
        drawAddr(stack[i + 2], x + 30 * 2, y)
        drawAddr(stack[i + 3], x + 30 * 3, y)
        drawAddr(stack[i + 4], x + 30 * 4, y)
        drawAddr(stack[i + 5], x + 30 * 5, y)

        y = y + 14
        i = i + 6
    end

    return 30 * 6, y - oy
end

local function box(x, y, w, h)
    love.graphics.setColor(255, 255, 0)
    love.graphics.rectangle('line', x, y, w, h)
    love.graphics.setColor(255, 255, 255)
end

local function drawInternalState()
    local PAD = 10

    local line = love.graphics.line

    love.graphics.setLineWidth(3)

    local x, y, w, h = PAD, PAD
    local w1, w2
    local xm, ym

    w, h = drawMemory(x, y)
    -- box(x, y, w, h)
    x = x + w + PAD

    line(x, -10, x, 330)
    x = x + PAD + 2

    w1, h = drawRegisters(x, y)
    -- box(x, y, w1, h)
    y = y + h + PAD

    line(x - PAD, y, x + w, y)
    y = y + PAD + 2

    w2, h = drawStack(x, y)
    -- box(x, y, w2, h)
    w = math.max(w1, w2)
    x = x + w + PAD

    line(x, -10, x, 330)
    x = x + PAD + 2

    y = PAD
    love.graphics.print("Sound: " .. chip8.ST, x, y)
    y = y + 14 + 4
    love.graphics.print("Delay: " .. chip8.DT, x, y)
    y = y + 14 + 4

    -- box(x, y, 64 * 3, 32 * 3)
end

-- love methods

function love.load(args)
    chip8 = chip8.new()

    -- TODO: do this properly
    -- love.filedropped(love.filesystem.newFile('demo.ch8'))

    -- iprint(chip8)

    chip8:loadProgram({
        0x6007, -- LD V0, 0x7
        0xF029, -- LD F, Vx
        0x6101, -- LD V1, 0x1
        0xD115, -- DRW V1, V1, 5
        0xD005, -- DRW V1, V1, 5
    })
end

function love.update(dt)
    chip8:update(dt / 100)
    -- for y = 0, 31 do
    --     for x = 0, 63 do
    --         io.write(chip8.display[y * 64 + x])
    --     end
    --     io.write('\n')
    -- end
    -- print('-------------------')
end

function love.draw()
    if displayInternalState then
        drawInternalState()
    end

    local w, h = chip8.width, chip8.height
    local display = chip8.display
    local rect = love.graphics.rectangle
    for y = 0, (h - 1) do
        for x = 0, (w - 1) do
            if display[y * w + x] > 0 then
                rect('fill', x * 10 + 1, y * 10 + 1, 8, 8)
            end
        end
    end
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    if key == 'f3' then
        displayInternalState = not displayInternalState
    end
end

function love.filedropped(file)
    print('dropped', file)
    file:open('r')
    chip8:loadProgramBinary(file:read())
end
