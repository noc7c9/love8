local chip8 = require 'chip8'
local internalsOverlay = require 'love8.internals-overlay'
local demo = require 'love8.demo-program'

local BEEP_FILE = 'beep.ogg'

local KEY_MAP = {
    ['1'] = 0x1, ['2'] = 0x2, ['3'] = 0x3, ['4'] = 0xc,
    ['q'] = 0x4, ['w'] = 0x5, ['e'] = 0x6, ['r'] = 0xd,
    ['a'] = 0x7, ['s'] = 0x8, ['d'] = 0x9, ['f'] = 0xe,
    ['z'] = 0xa, ['x'] = 0x0, ['c'] = 0xb, ['v'] = 0xf,
}

local Love8 = {}
Love8.__index = Love8

function Love8.new()
    local self = {}
    setmetatable(self, Love8)
    return self
end

function Love8:load(args)
    self.chip8 = chip8.new()

    self.displayInternals = false
    self.internalsOverlay = internalsOverlay.new(self.chip8)

    self.beep = love.audio.newSource(BEEP_FILE, 'static')
    self.beep:setLooping(true)

    -- parse args
    if #args > 1 then
        self.chip8:loadProgramBinary(arg[2])
    else
        self.chip8:loadProgram(demo)
    end
end

function Love8:update(dt)
    self.chip8:update(dt)

    if self.chip8.ST > 0 then
        self.beep:play()
    else
        self.beep:pause()
    end
end

function Love8:draw()
    if self.displayInternals then
        self.internalsOverlay:draw()
    end

    local w, h = self.chip8.width, self.chip8.height
    local display = self.chip8.display
    local rect = love.graphics.rectangle
    for y = 0, (h - 1) do
        for x = 0, (w - 1) do
            if display[y * w + x] > 0 then
                rect('fill', x * 10 + 1, y * 10 + 1, 8, 8)
            end
        end
    end
end

function Love8:keypressed(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'f3' then
        self.displayInternals = not self.displayInternals
    else
        if KEY_MAP[key] ~= nil then
            self.chip8.K[KEY_MAP[key]] = 1
        end
    end
end

function Love8:keyreleased(key)
    if KEY_MAP[key] ~= nil then
        self.chip8.K[KEY_MAP[key]] = 0
    end
end

function Love8:filedropped(file)
    file:open('r')
    self.chip8:loadProgramBinary(file:read())
end

function Love8:bindToLove()
    love.load        = function (...) self:load(...) end
    love.update      = function (...) self:update(...) end
    love.draw        = function (...) self:draw(...) end
    love.keypressed  = function (...) self:keypressed(...) end
    love.keyreleased = function (...) self:keyreleased(...) end
    love.filedropped = function (...) self:filedropped(...) end
end

return Love8
