local dec2hex = require('src.helpers').dec2hex

local interpreter = require('src.interpreter.init')

local tests = {}

local function test(name, code, func)
    table.insert(tests, {
        name = name,
        code = code,
        func = func
    })
end

local function runTests()
    local cpu = interpreter.new()
    for i, test in ipairs(tests) do
        print('Test ' .. i .. ': ' .. test.name)

        cpu:reset()
        cpu:loadProgram(test.code)
        test.func(cpu)
    end

    print('\n' .. #tests .. ' tests passed!')
end

local function runInLove2D()
    love.load = function ()
        runTests()
        love.event.quit()
    end
end

--- tests ---------------------------------------------------------------------

test('00E0 - CLS', {
    0x00E0, -- CLS
}, function (cpu)
    cpu.display[0] = 1
    cpu:runCycles()
    assert(cpu.display[0] == 0)
end)

test('00EE - RET', {
    0x6000, -- 200 LD V0, 0
    0x2210, -- 202 CALL 0x210
    0x1204, -- 204 JP 0x204

    0x7001, -- 206 ADD V0, 0x1
    0x220c, -- 208 CALL 0x20c
    0x00EE, -- 20a RET

    0x7002, -- 20c ADD V0, 0x2
    0x00EE, -- 20e RET

    0x7003, -- 210 ADD V0, 0x3
    0x2206, -- 212 CALL 0x206
    0x00EE, -- 214 RET
}, function (cpu)
    cpu:runCycles(200)

    assert(cpu.V[0x0] == 6)
    assert(#cpu.stack == 0)
end)

test('1nnn - JP addr', {
    0x6011, -- LD V0, 0x11
    0x6111, -- LD V1, 0x11
    0x6211, -- LD V2, 0x11
    0x6311, -- LD V3, 0x11
    0x120e, -- JP 0x20e
    0x6022, -- LD V0, 0x22
    0x6122, -- LD V1, 0x22
    0x6222, -- LD V2, 0x22
    0x6322, -- LD V3, 0x22
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0x11)
    assert(cpu.V[0x1] == 0x11)
    assert(cpu.V[0x2] == 0x22)
    assert(cpu.V[0x3] == 0x22)
end)

test('2nnn - CALL addr', {
    0x6011, -- LD V0, 0x11
    0x2206, -- CALL 0x206
    0x1204, -- JP 0x204

    0x6022, -- LD V0, 0x22
    0x1208, -- JP 0x208
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0x22)
    assert(#cpu.stack == 1)
end)

test('3xkk - SE Vx, byte', {
    0x60aa, -- LD V0, 0xaa
    0x30aa, -- SE V0, 0xaa
    0x60ff, -- LD V0, 0xff

    0x61ff, -- LD V1, 0xbb
    0x3100, -- SE V1, 0x00
    0x61aa, -- LD V1, 0xaa
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0xaa)
    assert(cpu.V[0x1] == 0xaa)
end)

test('4xkk - SNE Vx, byte', {
    0x60aa, -- LD V0, 0xaa
    0x40aa, -- SNE V0, 0xaa
    0x60ff, -- LD V0, 0xff

    0x61ff, -- LD V1, 0xbb
    0x4100, -- SNE V1, 0x00
    0x61aa, -- LD V1, 0xaa
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0xff)
    assert(cpu.V[0x1] == 0xff)
end)

test('5xy0 - SE Vx, Vy', {
    0x6a11, -- LD Va, 0x11
    0x6b11, -- LD Vb, 0x11
    0x5ab0, -- SE Va, Vb
    0x6aff, -- LD Va, 0xff

    0x6cff, -- LD Vc, 0xff
    0x6d11, -- LD Vd, 0x11
    0x5cd0, -- SE Vc, Vd
    0x6c11, -- LD Va, 0x11
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0x11)
    assert(cpu.V[0xc] == 0x11)
end)

test('6xkk - LD Vx, byte', {
    0x6001, -- LD V0, 0x01
    0x6101, -- LD V1, 0x01
    0x6202, -- LD V2, 0x02
    0x6303, -- LD V3, 0x03
    0x6405, -- LD V4, 0x05
    0x6508, -- LD V5, 0x08
    0x660d, -- LD V6, 0x0d
    0x6715, -- LD V7, 0x15
    0x6822, -- LD V8, 0x22
    0x6937, -- LD V9, 0x37
    0x6a59, -- LD Va, 0x59
    0x6b90, -- LD Vb, 0x90
    0x6ce9, -- LD Vc, 0xe9
    0x6d79, -- LD Vd, 0x79
    0x6e62, -- LD Ve, 0x62
    0x6fdb, -- LD Vf, 0xdb
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0x01)
    assert(cpu.V[0x1] == 0x01)
    assert(cpu.V[0x2] == 0x02)
    assert(cpu.V[0x3] == 0x03)
    assert(cpu.V[0x4] == 0x05)
    assert(cpu.V[0x5] == 0x08)
    assert(cpu.V[0x6] == 0x0d)
    assert(cpu.V[0x7] == 0x15)
    assert(cpu.V[0x8] == 0x22)
    assert(cpu.V[0x9] == 0x37)
    assert(cpu.V[0xa] == 0x59)
    assert(cpu.V[0xb] == 0x90)
    assert(cpu.V[0xc] == 0xe9)
    assert(cpu.V[0xd] == 0x79)
    assert(cpu.V[0xe] == 0x62)
    assert(cpu.V[0xf] == 0xdb)
end)

test('7xkk - ADD Vx, byte', {
    0x6a02, -- LD Va, 0x02
    0x7a02, -- ADD Va, 0x02
    0x7a02, -- ADD Va, 0x02
    0x7a02, -- ADD Va, 0x02
    0x7a02, -- ADD Va, 0x02
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0x0a)
end)

test('8xy0 - LD Vx, Vy', {
    0x6b04, -- LD Vb, 0x04
    0x80b0, -- LD V0, Vb
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xb] == 0x04)
    assert(cpu.V[0x0] == 0x04)
end)

test('8xy1 - OR Vx, Vy', {
    0x6a60, -- LD Va, 0x60 (0110 0000)
    0x6b06, -- LD Vb, 0x06 (0000 0110)
    0x8ab1, -- OR Va, Vb
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0x66)
    assert(cpu.V[0xb] == 0x06)
end)

test('8xy2 - AND Vx, Vy', {
    0x6a78, -- LD Va, 0x78 (0111 1000)
    0x6b1e, -- LD Vb, 0x1e (0001 1110)
    0x8ab2, -- AND Va, Vb
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0x18)
    assert(cpu.V[0xb] == 0x1e)
end)

test('8xy3 - XOR Vx, Vy', {
    0x6aff, -- LD Va, 0xff (1111 1111)
    0x6b1e, -- LD Vb, 0x1e (0001 1110)
    0x8ab3, -- XOR Va, Vb
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0xe1)
    assert(cpu.V[0xb] == 0x1e)
end)

test('8xy4 - ADD Vx, Vy', {
    0x6a07, -- LD Va, 0x07
    0x6b08, -- LD Vb, 0x08
    0x8ab4, -- ADD Va, Vb

    0x6aff, -- LD Va, 0xff
    0x6b02, -- LD Vb, 0x02
    0x8ab4, -- ADD Va, Vb
}, function (cpu)
    cpu:runCycles(3)

    assert(cpu.V[0xa] == 0x0f)
    assert(cpu.V[0xb] == 0x08)
    assert(cpu.V[0xf] == 0)

    cpu:runCycles()

    assert(cpu.V[0xa] == 0x01)
    assert(cpu.V[0xb] == 0x02)
    assert(cpu.V[0xf] == 1)
end)

test('8xy5 - SUB Vx, Vy', {
    0x6a0a, -- LD Va, 0x0a
    0x6b05, -- LD Vb, 0x05
    0x8ab5, -- SUB Va, Vb

    0x6a05, -- LD Va, 0x05
    0x6b0a, -- LD Vb, 0x0a
    0x8ab5, -- SUB Va, Vb
}, function (cpu)
    cpu:runCycles(3)

    assert(cpu.V[0xa] == 0x05)
    assert(cpu.V[0xb] == 0x05)
    assert(cpu.V[0xf] == 1)

    cpu:runCycles()

    assert(cpu.V[0xa] == 0xfb)
    assert(cpu.V[0xb] == 0x0a)
    assert(cpu.V[0xf] == 0)
end)

test('8xy6 - SHR Vx, Vy', {
    0x6aff, -- LD Va, 0xff
    0x6b06, -- LD Vb, 0x05
    0x8ab6, -- SHR Vx, Vy
    0x8aa6, -- SHR Vx, Vx
}, function (cpu)
    cpu:runCycles(3)

    assert(cpu.V[0xa] == 0x03)
    assert(cpu.V[0xb] == 0x06)
    assert(cpu.V[0xf] == 0)

    cpu:runCycles(1)

    assert(cpu.V[0xa] == 0x01)
    assert(cpu.V[0xb] == 0x06)
    assert(cpu.V[0xf] == 1)
end)

test('8xy7 - SUBN Vx, Vy', {
    0x6a07, -- LD Va, 0x0a
    0x6b0a, -- LD Vb, 0x05
    0x8ab7, -- SUBN Va, Vb

    0x6a0a, -- LD Va, 0x0a
    0x6b05, -- LD Vb, 0x05
    0x8ab7, -- SUBN Va, Vb
}, function (cpu)
    cpu:runCycles(3)

    assert(cpu.V[0xa] == 0x03)
    assert(cpu.V[0xb] == 0x0a)
    assert(cpu.V[0xf] == 1)

    cpu:runCycles()

    assert(cpu.V[0xa] == 0xfb)
    assert(cpu.V[0xb] == 0x05)
    assert(cpu.V[0xf] == 0)
end)

test('8xyE - SHL Vx, Vy', {
    0x6aff, -- LD Va, 0xff
    0x6b60, -- LD Vb, 0x60
    0x8abE, -- SHR Vx, Vy
    0x8aaE, -- SHR Vx, Vx
}, function (cpu)
    cpu:runCycles(3)

    assert(cpu.V[0xa] == 0xc0)
    assert(cpu.V[0xb] == 0x60)
    assert(cpu.V[0xf] == 0)

    cpu:runCycles(1)

    assert(cpu.V[0xa] == 0x80)
    assert(cpu.V[0xb] == 0x60)
    assert(cpu.V[0xf] == 1)
end)

test('9xy0 - SNE Vx, Vy', {
    0x6aff, -- LD Va, 0xff
    0x6bff, -- LD Vb, 0xff
    0x9ab0, -- SNE Va, Vb
    0x6a11, -- LD Va, 0x11

    0x6c11, -- LD Vc, 0x11
    0x6dff, -- LD Vd, 0xff
    0x9cd0, -- SNE Vc, Vd
    0x6cff, -- LD Vc, 0xff
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0xa] == 0x11)
    assert(cpu.V[0xc] == 0x11)
end)

test('Annn - LD I, addr', {
    0xA111, -- LD I, 0x111
    0xA222, -- LD I, 0x222
    0xA333, -- LD I, 0x333
}, function (cpu)
    cpu:runCycles(1)
    assert(cpu.I == 0x111)
    cpu:runCycles(1)
    assert(cpu.I == 0x222)
    cpu:runCycles(1)
    assert(cpu.I == 0x333)
end)

test('Bnnn - JP V0, addr', {
    0x600e, -- LD V0, 0x0e
    0x6111, -- LD V1, 0x11
    0x6211, -- LD V2, 0x11
    0x6311, -- LD V3, 0x11
    0xB200, -- JP V0, 0x200
    0x6022, -- LD V0, 0x22
    0x6122, -- LD V1, 0x22
    0x6222, -- LD V2, 0x22
    0x6322, -- LD V3, 0x22
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0x0e)
    assert(cpu.V[0x1] == 0x11)
    assert(cpu.V[0x2] == 0x22)
    assert(cpu.V[0x3] == 0x22)
end)

test('Cxkk - RND Vx, byte', {
    0x6000, -- LD V0, 0
    0x6100, -- LD V1, 0
    0x6200, -- LD V2, 0
    0x6300, -- LD V3, 0
    0x6400, -- LD V4, 0
    0x6500, -- LD V5, 0
    0x6600, -- LD V6, 0
    0x6700, -- LD V7, 0
    0x6800, -- LD V8, 0
    0x6900, -- LD V9, 0
    0x6a00, -- LD VA, 0
    0x6b00, -- LD VB, 0
    0x6c00, -- LD VC, 0
    0x6d00, -- LD VD, 0
    0x6e00, -- LD VE, 0
    0x6f00, -- LD VF, 0

    0xC0ff, -- RND V0, 0xff
    0xC1ff, -- RND V1, 0xff
    0xC2ff, -- RND V2, 0xff
    0xC3ff, -- RND V3, 0xff
    0xC4ff, -- RND V4, 0xff
    0xC5ff, -- RND V5, 0xff
    0xC6ff, -- RND V6, 0xff
    0xC7ff, -- RND V7, 0xff
    0xC8ff, -- RND V8, 0xff
    0xC9ff, -- RND V9, 0xff
    0xCaff, -- RND VA, 0xff
    0xCbff, -- RND VB, 0xff
    0xCcff, -- RND VC, 0xff
    0xCdff, -- RND VD, 0xff
    0xCeff, -- RND VE, 0xff
    0xCfff, -- RND VF, 0xff
}, function (cpu)
    cpu:runCycles()

    -- note: there is a chance this test will fail
    assert(
        cpu.V[0x0] > 0 or
        cpu.V[0x1] > 0 or
        cpu.V[0x2] > 0 or
        cpu.V[0x3] > 0 or
        cpu.V[0x4] > 0 or
        cpu.V[0x5] > 0 or
        cpu.V[0x6] > 0 or
        cpu.V[0x7] > 0 or
        cpu.V[0x8] > 0 or
        cpu.V[0x9] > 0 or
        cpu.V[0xa] > 0 or
        cpu.V[0xb] > 0 or
        cpu.V[0xc] > 0 or
        cpu.V[0xd] > 0 or
        cpu.V[0xf] > 0 or
        cpu.V[0xe] > 0
    )
end)

test('Dxyn - DRW Vx, Vy, nybble', {
    0x6007, -- LD V0, 0x7
    0xF029, -- LD F, Vx
    0x6101, -- LD V1, 0x1
    0xD115, -- DRW V1, V1, 5
    0xD115, -- DRW V1, V1, 5
}, function (cpu)
    assert(cpu.display[cpu.width + 1] == 0)
    cpu:runCycles(4)
    assert(cpu.display[cpu.width + 1] == 1)
    assert(cpu.V[0xf] == 0)
    cpu:runCycles(1)
    assert(cpu.V[0xf] == 1)
    assert(cpu.display[cpu.width + 1] == 0)
end)

test('Ex9E - SKP Vx', {
    0x6001, -- LD V0, 0x1

    0x61aa, -- LD V0, 0xaa
    0xE09E, -- SKP V0
    0x61ff, -- LD V0, 0xff

    0x62ff, -- LD V1, 0xbb
    0xE09E, -- SKP V0
    0x62aa, -- LD V1, 0xaa
}, function (cpu)
    cpu.K[0x1] = 1
    cpu:runCycles(4)
    cpu.K[0x1] = 0
    cpu:runCycles()

    assert(cpu.V[0x1] == 0xaa)
    assert(cpu.V[0x2] == 0xaa)
end)

test('ExA1 - SKNP Vx', {
    0x6001, -- LD V0, 1

    0x61aa, -- LD V0, 0xaa
    0xE0A1, -- SKNP V0
    0x61ff, -- LD V0, 0xff

    0x62ff, -- LD V1, 0xbb
    0xE0A1, -- SKNP V0
    0x62aa, -- LD V1, 0xaa
}, function (cpu)
    cpu.K[0x1] = 0
    cpu:runCycles(4)
    cpu.K[0x1] = 1
    cpu:runCycles()

    assert(cpu.V[0x1] == 0xaa)
    assert(cpu.V[0x2] == 0xaa)
end)

test('Fx07 - LD Vx, DT', {
    0x61ff, -- LD V1, 0xff
    0x6011, -- LD V0, 0x11
    0xF015, -- LD DT, V0
    0xF107, -- LD V1, DT
}, function (cpu)
    cpu:runCycles(1)
    assert(cpu.V[0x1] == 0xff)
    cpu:runCycles()
    assert(cpu.V[0x1] ~= 0xff) -- note: DT could change so no direct compare
end)

test('Fx0A - LD Vx, K', {
    0x60ff, -- LD V0, 0xff
    0xF10A, -- LD V1, K
    0x6011, -- LD V0, 0x11
}, function (cpu)
    cpu:runCycles(10)
    assert(cpu.V[0x0] == 0xff)
    cpu.K[0xa] = 1
    cpu:runCycles()
    assert(cpu.V[0x0] == 0x11)
    assert(cpu.V[0x1] == 0xa)
end)

test('Fx15 - LD DT, Vx', {
    0x60ff, -- LD V0, 0xff
    0xF015, -- LD DT, V0
}, function (cpu)
    cpu:runCycles()

    assert(cpu.DT ~= 0) -- note: DT would change so no direct compare
end)

test('Fx18 - LD ST, Vx', {
    0x6011, -- LD V0, 0x11
    0xF018, -- LD ST, V0
}, function (cpu)
    cpu:runCycles()

    assert(cpu.ST ~= 0)
end)

test('Fx1E - ADD I, Vx', {
    0xA100, -- LD I, 0x100
    0x6011, -- LD V0, 0x11
    0xF01E, -- ADD I, V0
}, function (cpu)
    cpu:runCycles(1)
    assert(cpu.I == 0x100)
    cpu:runCycles()
    assert(cpu.I == 0x111)
end)

test('Fx29 - LD F, Vx', {
    0x6007, -- LD V0, 0x7
    0xF029, -- LD F, V0
}, function (cpu)
    cpu:runCycles()

    assert(cpu.memory[cpu.I + 0] == 0xf0)
    assert(cpu.memory[cpu.I + 1] == 0x10)
    assert(cpu.memory[cpu.I + 2] == 0x20)
    assert(cpu.memory[cpu.I + 3] == 0x40)
    assert(cpu.memory[cpu.I + 4] == 0x40)
end)

test('Fx33 - LD B, Vx', {
    0x607b, -- LD V0, 0x7b

    0xA300, -- LD I, 0x300
    0xF033, -- LD B, V0
}, function (cpu)
    cpu:runCycles()

    assert(cpu.memory[0x300] == 1)
    assert(cpu.memory[0x301] == 2)
    assert(cpu.memory[0x302] == 3)

    assert(cpu.I == 0x300)
end)

test('Fx55 - LD [I], Vx', {
    0x6002, -- LD V0, 0x02
    0x6104, -- LD V1, 0x04
    0x6208, -- LD V2, 0x08
    0x6310, -- LD V3, 0x10
    0x6420, -- LD V4, 0x20

    0xA300, -- LD I, 0x300
    0xF255, -- LD [I], V2
}, function (cpu)
    cpu:runCycles()

    assert(cpu.memory[0x300] == 0x02)
    assert(cpu.memory[0x301] == 0x04)
    assert(cpu.memory[0x302] == 0x08)
    assert(cpu.memory[0x303] == nil)
    assert(cpu.memory[0x304] == nil)

    assert(cpu.I == 0x303)
end)

test('Fx65 - LD Vx, [I]', {
    0x6002, -- LD V0, 0x02
    0x6104, -- LD V1, 0x04
    0x6208, -- LD V2, 0x08
    0x6310, -- LD V3, 0x10
    0x6420, -- LD V4, 0x20

    0xA300, -- LD I, 0x300
    0xF255, -- LD [I], V2

    0x6000, -- LD V0, 0x00
    0x6100, -- LD V1, 0x00
    0x6200, -- LD V2, 0x00
    0x6300, -- LD V3, 0x00
    0x6400, -- LD V4, 0x00

    0xA300, -- LD I, 0x300
    0xF265, -- LD V2, [I]
}, function (cpu)
    cpu:runCycles()

    assert(cpu.V[0x0] == 0x02)
    assert(cpu.V[0x1] == 0x04)
    assert(cpu.V[0x2] == 0x08)
    assert(cpu.V[0x3] == 0x00)
    assert(cpu.V[0x4] == 0x00)

    assert(cpu.I == 0x303)
end)

runInLove2D()
