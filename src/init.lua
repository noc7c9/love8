local interpreter = require('src.interpreter')
local internalsOverlay = require('src.internals-overlay')
local demo = require('src.demo-program')

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

    -- bind to Love2D
    love.load        = function (...) self:load(...) end
    love.update      = function (...) self:update(...) end
    love.draw        = function (...) self:draw(...) end
    love.keypressed  = function (...) self:keypressed(...) end
    love.keyreleased = function (...) self:keyreleased(...) end
    love.filedropped = function (...) self:filedropped(...) end

    return self
end

function Love8:load(args)
    self.interpreter = interpreter.new()

    self.displayInternals = false
    self.internalsOverlay = internalsOverlay.new(self.interpreter)

    self.beep = love.audio.newSource(BEEP_FILE, 'static')
    self.beep:setLooping(true)

    -- parse args
    if #args > 0 then
        file = args[1]
        file = file:gsub('\\', '/')
        info = love.filesystem.getInfo(file)
        if info == nil then
            print(file, 'not found')
            love.event.quit(1)
        else
            contents = love.filesystem.read(file)
            self.interpreter:loadProgramBinary(contents)
        end
    else
        self.interpreter:loadProgram(demo)
    end
end

function Love8:update(dt)
    self.interpreter:update(dt)

    if self.interpreter.ST > 0 then
        self.beep:play()
    else
        self.beep:pause()
    end
end

function Love8:draw()
    if self.displayInternals then
        self.internalsOverlay:draw()
    end

    local w, h = self.interpreter.width, self.interpreter.height
    local display = self.interpreter.display
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
            self.interpreter.K[KEY_MAP[key]] = 1
        end
    end
end

function Love8:keyreleased(key)
    if KEY_MAP[key] ~= nil then
        self.interpreter.K[KEY_MAP[key]] = 0
    end
end

function Love8:filedropped(file)
    file:open('r')
    self.interpreter:loadProgramBinary(file:read())
end

-- Start Love8
Love8.new()
