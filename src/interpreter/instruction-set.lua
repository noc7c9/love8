local dec2hex = require('src.helpers').dec2hex

local BIT = bit

-- references:
-- http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#2.5
-- http://mattmik.com/files/chip8/mastering/chip8.html
-- https://github.com/alexanderdickson/Chip-8-Emulator
-- https://github.com/mir3z/chip8-emu/

-- instruction execution code
---

-- 0nnn - SYS addr
-- Jump to a machine code routine at nnn.
local function i_0nnn_SYS_addr(cpu, instruction)
    -- ignored

    cpu.ip = cpu.ip + 2
end

-- 00E0 - CLS
-- Clear the display.
local function i_00E0_CLS(cpu, instruction)
    cpu:clearDisplay()

    cpu.ip = cpu.ip + 2
end

-- 00EE - RET
-- Return from a subroutine.
local function i_00EE_RET(cpu, instruction)
    cpu.ip = table.remove(cpu.stack) + 2
end

-- 1nnn - JP addr
-- Jump to location nnn.
local function i_1nnn_JP_addr(cpu, instruction)
    cpu.ip = instruction._nnn
end

-- 2nnn - CALL addr
-- Call subroutine at nnn.
local function i_2nnn_CALL_addr(cpu, instruction)
    table.insert(cpu.stack, cpu.ip)
    cpu.ip = instruction._nnn
end

-- 3xkk - SE Vx, byte
-- Skip next instruction if Vx = kk.
local function i_3xkk_SE_Vx_byte(cpu, instruction)
    if cpu.V[instruction._x__] == instruction.__kk then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- 4xkk - SNE Vx, byte
-- Skip next instruction if Vx != kk.
local function i_4xkk_SNE_Vx_byte(cpu, instruction)
    if cpu.V[instruction._x__] ~= instruction.__kk then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- 5xy0 - SE Vx, Vy
-- Skip next instruction if Vx = Vy.
local function i_5xy0_SE_Vx_Vy(cpu, instruction)
    if cpu.V[instruction._x__] == cpu.V[instruction.__y_] then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- 6xkk - LD Vx, byte
-- Set Vx = kk.
local function i_6xkk_LD_Vx_byte(cpu, instruction)
    cpu.V[instruction._x__] = instruction.__kk

    cpu.ip = cpu.ip + 2
end

-- 7xkk - ADD Vx, byte
-- Set Vx = Vx + kk.
local function i_7xkk_ADD_Vx_byte(cpu, instruction)
    local v = cpu.V[instruction._x__] + instruction.__kk
    if v > 0xff then
        v = v - 0x100
    end
    cpu.V[instruction._x__] = v

    cpu.ip = cpu.ip + 2
end

-- 8xy0 - LD Vx, Vy
-- Set Vx = Vy.
local function i_8xy0_LD_Vx_Vy(cpu, instruction)
    cpu.V[instruction._x__] = cpu.V[instruction.__y_]

    cpu.ip = cpu.ip + 2
end

-- 8xy1 - OR Vx, Vy
-- Set Vx = Vx OR Vy.
local function i_8xy1_OR_Vx_Vy(cpu, instruction)
    cpu.V[instruction._x__] =
        BIT.bor(cpu.V[instruction._x__], cpu.V[instruction.__y_])

    cpu.ip = cpu.ip + 2
end

-- 8xy2 - AND Vx, Vy
-- Set Vx = Vx AND Vy.
local function i_8xy2_AND_Vx_Vy(cpu, instruction)
    cpu.V[instruction._x__] =
        BIT.band(cpu.V[instruction._x__], cpu.V[instruction.__y_])

    cpu.ip = cpu.ip + 2
end

-- 8xy3 - XOR Vx, Vy
-- Set Vx = Vx XOR Vy.
local function i_8xy3_XOR_Vx_Vy(cpu, instruction)
    cpu.V[instruction._x__] =
        BIT.bxor(cpu.V[instruction._x__], cpu.V[instruction.__y_])

    cpu.ip = cpu.ip + 2
end

-- 8xy4 - ADD Vx, Vy
-- Set Vx = Vx + Vy, set VF = carry.
local function i_8xy4_ADD_Vx_Vy(cpu, instruction)
    local v = cpu.V[instruction._x__] + cpu.V[instruction.__y_]
    cpu.V[0xf] = 0
    if v > 0xff then
        v = v - 0x100
        cpu.V[0xf] = 1
    end
    cpu.V[instruction._x__] = v

    cpu.ip = cpu.ip + 2
end

-- 8xy5 - SUB Vx, Vy
-- Set Vx = Vx - Vy, set VF = NOT borrow.
local function i_8xy5_SUB_Vx_Vy(cpu, instruction)
    local v = cpu.V[instruction._x__] - cpu.V[instruction.__y_]
    cpu.V[0xf] = 1
    if v < 0 then
        v = v + 0x100
        cpu.V[0xf] = 0
    end
    cpu.V[instruction._x__] = v

    cpu.ip = cpu.ip + 2
end

-- 8xy6 - SHR Vx, Vy
-- Set Vx = Vy SHR 1, set VF = bit shifted out
local function i_8xy6_SHR_Vx_Vy(cpu, instruction)
    cpu.V[0xf] = BIT.band(0x1, cpu.V[instruction.__y_])
    cpu.V[instruction._x__] = BIT.rshift(cpu.V[instruction.__y_], 1)

    cpu.ip = cpu.ip + 2
end

-- 8xy7 - SUBN Vx, Vy
-- Set Vx = Vy - Vx, set VF = NOT borrow.
local function i_8xy7_SUBN_Vx_Vy(cpu, instruction)
    local v = cpu.V[instruction.__y_] - cpu.V[instruction._x__]
    cpu.V[0xf] = 1
    if v < 0 then
        v = v + 0x100
        cpu.V[0xf] = 0
    end
    cpu.V[instruction._x__] = v

    -- If Vy > Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy,
    -- and the results stored in Vx.
    cpu.ip = cpu.ip + 2
end

-- 8xyE - SHL Vx, Vy
-- Set Vx = Vy SHL 1, set VF = bit shifted out
local function i_8xyE_SHL_Vx_Vy(cpu, instruction)
    cpu.V[0xf] = BIT.rshift(cpu.V[instruction.__y_], 7)
    cpu.V[instruction._x__] = BIT.band(0xff, BIT.lshift(cpu.V[instruction.__y_], 1))

    cpu.ip = cpu.ip + 2
end

-- 9xy0 - SNE Vx, Vy
-- Skip next instruction if Vx != Vy.
local function i_9xy0_SNE_Vx_Vy(cpu, instruction)
    if cpu.V[instruction._x__] ~= cpu.V[instruction.__y_] then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- Annn - LD I, addr
-- Set I = nnn.
local function i_Annn_LD_I_addr(cpu, instruction)
    cpu.I = instruction._nnn

    cpu.ip = cpu.ip + 2
end

-- Bnnn - JP V0, addr
-- Jump to location nnn + V0.
local function i_Bnnn_JP_V0_addr(cpu, instruction)
    cpu.ip = instruction._nnn + cpu.V[0x0]
end

-- Cxkk - RND Vx, byte
-- Set Vx = random byte AND kk.
local function i_Cxkk_RND_Vx_byte(cpu, instruction)
    cpu.V[instruction._x__] = BIT.band(math.random(0, 0xff), instruction.__kk)

    cpu.ip = cpu.ip + 2
end

-- Dxyn - DRW Vx, Vy, nybble
-- Display n-byte sprite starting at memory location
-- I at (Vx, Vy), set VF = collision.
local function i_Dxyn_DRW_Vx_Vy_nybble(cpu, instruction)
    local i, x, y
    local w, h = 8, instruction.___n
    local ox, oy = cpu.V[instruction._x__], cpu.V[instruction.__y_]
    local byte, bit

    local display = cpu.display

    cpu.V[0xf] = 0
    for y = 0, (h - 1) do
        byte = cpu.memory[cpu.I + y] or 0
        for x = 1, w do
            x = w - x
            i = (y + oy) * cpu.width + (x + ox)

            bit = BIT.band(byte, 0x1)
            byte = BIT.rshift(byte, 1)

            if bit == 1 then
                if display[i] == 1 then
                    cpu.V[0xf] = 1
                    display[i] = 0
                else
                    display[i] = 1
                end
            end
        end
    end

    cpu.ip = cpu.ip + 2
end

-- Ex9E - SKP Vx
-- Skip next instruction if key with the value of Vx is pressed.
local function i_Ex9E_SKP_Vx(cpu, instruction)
    if (cpu.K[cpu.V[instruction._x__]] or 0) > 0 then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- ExA1 - SKNP Vx
-- Skip next instruction if key with the value of Vx is not pressed.
local function i_ExA1_SKNP_Vx(cpu, instruction)
    if (cpu.K[cpu.V[instruction._x__]] or 0) <= 0 then
        cpu.ip = cpu.ip + 4
    else
        cpu.ip = cpu.ip + 2
    end
end

-- Fx07 - LD Vx, DT
-- Set Vx = delay timer value.
local function i_Fx07_LD_Vx_DT(cpu, instruction)
    cpu.V[instruction._x__] = cpu.DT

    cpu.ip = cpu.ip + 2
end

-- Fx0A - LD Vx, K
-- Wait for a key press, store the value of the key in Vx.
local function i_Fx0A_LD_Vx_K(cpu, instruction)
    cpu.waitingForKeyPress = instruction._x__

    cpu.ip = cpu.ip + 2
end

-- Fx15 - LD DT, Vx
-- Set delay timer = Vx.
local function i_Fx15_LD_DT_Vx(cpu, instruction)
    cpu.DT = cpu.V[instruction._x__]

    cpu.ip = cpu.ip + 2
end

-- Fx18 - LD ST, Vx
-- Set sound timer = Vx.
local function i_Fx18_LD_ST_Vx(cpu, instruction)
    cpu.ST = cpu.V[instruction._x__]

    cpu.ip = cpu.ip + 2
end

-- Fx1E - ADD I, Vx
-- Set I = I + Vx.
local function i_Fx1E_ADD_I_Vx(cpu, instruction)
    cpu.I = cpu.I + cpu.V[instruction._x__]

    cpu.ip = cpu.ip + 2
end

-- Fx29 - LD F, Vx
-- Set I = location of sprite for digit Vx.
local function i_Fx29_LD_F_Vx(cpu, instruction)
    cpu.I = cpu.V[instruction._x__] * 5

    cpu.ip = cpu.ip + 2
end

-- Fx33 - LD B, Vx
-- Store BCD representation of Vx in memory locations I, I+1,
-- and I+2.
local function i_Fx33_LD_B_Vx(cpu, instruction)
    local num = cpu.V[instruction._x__]
    cpu.memory[cpu.I + 0] = math.floor(num / 100)
    num = num % 100
    cpu.memory[cpu.I + 1] = math.floor(num / 10)
    num = num % 10
    cpu.memory[cpu.I + 2] = num

    cpu.ip = cpu.ip + 2
end

-- Fx55 - LD [I], Vx
-- Store registers V0 through Vx in memory starting at location I.
-- I = I + x + 1
local function i_Fx55_LD_I_Vx(cpu, instruction)
    for x = 0, instruction._x__ do
        cpu.memory[cpu.I] = cpu.V[x]
        cpu.I = cpu.I + 1
    end

    cpu.ip = cpu.ip + 2
end

-- Fx65 - LD Vx, [I]
-- Read registers V0 through Vx from memory starting at location I.
-- I = I + x + 1
local function i_Fx65_LD_Vx_I(cpu, instruction)
    for x = 0, instruction._x__ do
        cpu.V[x] = cpu.memory[cpu.I]
        cpu.I = cpu.I + 1
    end

    cpu.ip = cpu.ip + 2
end

-- instruction decoding code
---
local mapping = {
    [0x0] = function (cpu, instruction)
        if instruction.__kk == 0x00E0 then
            i_00E0_CLS(cpu, instruction)
        elseif instruction.__kk == 0x00EE then
            i_00EE_RET(cpu, instruction)
        else
            i_0nnn_SYS_addr(cpu, instruction)
        end
    end,
    [0x1] = i_1nnn_JP_addr,
    [0x2] = i_2nnn_CALL_addr,
    [0x3] = i_3xkk_SE_Vx_byte,
    [0x4] = i_4xkk_SNE_Vx_byte,
    [0x5] = function (cpu, instruction)
        if instruction.___n ~= 0 then
            error('Invalid Instruction: ' .. dec2hex(instruction.raw))
        end

        i_5xy0_SE_Vx_Vy(cpu, instruction)
    end,
    [0x6] = i_6xkk_LD_Vx_byte,
    [0x7] = i_7xkk_ADD_Vx_byte,
    [0x8] = function (cpu, instruction)
        local f = ({
            [0x0] = i_8xy0_LD_Vx_Vy,
            [0x1] = i_8xy1_OR_Vx_Vy,
            [0x2] = i_8xy2_AND_Vx_Vy,
            [0x3] = i_8xy3_XOR_Vx_Vy,
            [0x4] = i_8xy4_ADD_Vx_Vy,
            [0x5] = i_8xy5_SUB_Vx_Vy,
            [0x6] = i_8xy6_SHR_Vx_Vy,
            [0x7] = i_8xy7_SUBN_Vx_Vy,
            [0xE] = i_8xyE_SHL_Vx_Vy,
        })[instruction.___n]

        if not f then
            error('Invalid Instruction: ' .. dec2hex(instruction.raw))
        end

        f(cpu, instruction)
    end,
    [0x9] = function (cpu, instruction)
        if instruction.___n ~= 0 then
            error('Invalid Instruction: ' .. dec2hex(instruction.raw))
        end

        i_9xy0_SNE_Vx_Vy(cpu, instruction)
    end,
    [0xA] = i_Annn_LD_I_addr,
    [0xB] = i_Bnnn_JP_V0_addr,
    [0xC] = i_Cxkk_RND_Vx_byte,
    [0xD] = i_Dxyn_DRW_Vx_Vy_nybble,
    [0xE] = function (cpu, instruction)
        local f = ({
            [0x9E] = i_Ex9E_SKP_Vx,
            [0xA1] = i_ExA1_SKNP_Vx,
        })[instruction.__kk]

        if not f then
            error('Invalid Instruction: ' .. dec2hex(instruction.raw))
        end

        f(cpu, instruction)
    end,
    [0xF] = function (cpu, instruction)
        local f = ({
            [0x07] = i_Fx07_LD_Vx_DT,
            [0x0A] = i_Fx0A_LD_Vx_K,
            [0x15] = i_Fx15_LD_DT_Vx,
            [0x18] = i_Fx18_LD_ST_Vx,
            [0x1E] = i_Fx1E_ADD_I_Vx,
            [0x29] = i_Fx29_LD_F_Vx,
            [0x33] = i_Fx33_LD_B_Vx,
            [0x55] = i_Fx55_LD_I_Vx,
            [0x65] = i_Fx65_LD_Vx_I,
        })[instruction.__kk]

        if not f then
            error('Invalid Instruction: ' .. dec2hex(instruction.raw))
        end

        f(cpu, instruction)
    end,
}

return function (instruction)
    local f = mapping[instruction.o___]
    if not f then
        error('Invalid Instruction: ' .. dec2hex(instruction.raw))
    end
    return f
end
