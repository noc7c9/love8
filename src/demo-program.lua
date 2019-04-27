return {
    -- Load sprite for 7
    0x6007, -- LD V0, 0x7
    0xF029, -- LD F, Vx

    -- Draw the 7 sprite at the (1, 1)
    0x6101, -- LD V1, 0x1
    0xD115, -- DRW V1, V1, 5

    -- Draw the 7 sprite at the (7, 7)
    0xD005, -- DRW V0, V0, 5

    -- Set the sound timer to 60 (1 sec)
    0x603c, -- LD V0, 0x3c
    0xF018, -- LD ST, V0
}
