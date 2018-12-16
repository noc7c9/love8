local dec2hex = require('src.helpers').dec2hex
local print = love.graphics.print

local InternalsOverlay = {}
InternalsOverlay.__index = InternalsOverlay

function InternalsOverlay.new(chip8)
    local self = {
        chip8 = chip8
    }
    setmetatable(self, InternalsOverlay)
    return self
end

function InternalsOverlay:drawMemory(ox, oy)
    local color = love.graphics.setColor

    local mem = self.chip8.memory
    local ip = self.chip8.ip

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

function InternalsOverlay:drawRegisters(ox, oy)
    local V = self.chip8.V
    local x, y = ox, oy

    print("Registers:", x, y)

    y = y + 14 + 4
    print("v0=" .. dec2hex(V[0x0], 2), x + 46 * 0, y)
    print("v1=" .. dec2hex(V[0x1], 2), x + 46 * 1, y)
    print("v2=" .. dec2hex(V[0x2], 2), x + 46 * 2, y)
    print("v3=" .. dec2hex(V[0x3], 2), x + 46 * 3, y)
    y = y + 14
    print("v4=" .. dec2hex(V[0x4], 2), x + 46 * 0, y)
    print("v5=" .. dec2hex(V[0x5], 2), x + 46 * 1, y)
    print("v6=" .. dec2hex(V[0x6], 2), x + 46 * 2, y)
    print("v7=" .. dec2hex(V[0x7], 2), x + 46 * 3, y)
    y = y + 14
    print("v8=" .. dec2hex(V[0x8], 2), x + 46 * 0, y)
    print("v9=" .. dec2hex(V[0x9], 2), x + 46 * 1, y)
    print("vA=" .. dec2hex(V[0xA], 2), x + 46 * 2, y)
    print("vB=" .. dec2hex(V[0xB], 2), x + 46 * 3, y)
    y = y + 14
    print("vC=" .. dec2hex(V[0xC], 2), x + 46 * 0, y)
    print("vD=" .. dec2hex(V[0xD], 2), x + 46 * 1, y)
    print("vE=" .. dec2hex(V[0xE], 2), x + 46 * 2, y)
    print("vF=" .. dec2hex(V[0xF], 2), x + 46 * 3, y)

    y = y + 14 + 4
    print("I=" .. dec2hex(self.chip8.I, 3), x, y)

    return 46 * 4, y - oy + 14
end

function InternalsOverlay:drawKeys(ox, oy)
    local K = self.chip8.K
    local x, y = ox, oy

    print("Keys:", x, y)

    y = y + 14 + 4
    print("1=" .. dec2hex(K[0x1], 2), x + 46 * 0, y)
    print("2=" .. dec2hex(K[0x2], 2), x + 46 * 1, y)
    print("3=" .. dec2hex(K[0x3], 2), x + 46 * 2, y)
    print("C=" .. dec2hex(K[0xc], 2), x + 46 * 3, y)
    y = y + 14
    print("4=" .. dec2hex(K[0x4], 2), x + 46 * 0, y)
    print("5=" .. dec2hex(K[0x5], 2), x + 46 * 1, y)
    print("6=" .. dec2hex(K[0x6], 2), x + 46 * 2, y)
    print("D=" .. dec2hex(K[0xD], 2), x + 46 * 3, y)
    y = y + 14
    print("7=" .. dec2hex(K[0x7], 2), x + 46 * 0, y)
    print("8=" .. dec2hex(K[0x8], 2), x + 46 * 1, y)
    print("9=" .. dec2hex(K[0x9], 2), x + 46 * 2, y)
    print("E=" .. dec2hex(K[0xE], 2), x + 46 * 3, y)
    y = y + 14
    print("A=" .. dec2hex(K[0xA], 2), x + 46 * 0, y)
    print("0=" .. dec2hex(K[0x0], 2), x + 46 * 1, y)
    print("B=" .. dec2hex(K[0xB], 2), x + 46 * 2, y)
    print("F=" .. dec2hex(K[0xF], 2), x + 46 * 3, y)

    return 46 * 4, y - oy + 14
end

function InternalsOverlay:drawStack(ox, oy)
    local stack = self.chip8.stack

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

function InternalsOverlay:draw()
    local function box(x, y, w, h)
        love.graphics.setColor(255, 255, 0)
        love.graphics.rectangle('line', x, y, w, h)
        love.graphics.setColor(255, 255, 255)
    end

    local PAD = 10

    local line = love.graphics.line

    love.graphics.setLineWidth(3)

    local x, y, w, h = PAD, PAD
    local w1, w2
    local xm, ym

    w, h = self:drawMemory(x, y)
    -- box(x, y, w, h)
    x = x + w + PAD

    line(x, -10, x, 330)
    x = x + PAD + 2

    w1, h = self:drawRegisters(x, y)
    -- box(x, y, w1, h)
    y = y + h + PAD

    line(x - PAD, y, x + w, y)
    y = y + PAD + 2

    w2, h = self:drawStack(x, y)
    -- box(x, y, w2, h)
    w = math.max(w1, w2)
    x = x + w + PAD

    line(x, -10, x, 330)
    x = x + PAD + 2

    y = PAD
    love.graphics.print("Sound: " .. self.chip8.ST, x, y)
    y = y + 14 + 4
    love.graphics.print("Delay: " .. self.chip8.DT, x, y)
    y = y + 14 + PAD

    line(x - PAD, y, 640, y)
    y = y + PAD + 2

    w, h = self:drawKeys(x, y)
    y = y + h + PAD
end

return InternalsOverlay
