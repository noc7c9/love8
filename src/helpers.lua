local inspect = require 'lib.inspect'

local helpers = {}

function helpers.iprint(...)
    local args = {...}
    for i, v in ipairs(args) do
        args[i] = inspect(v)
    end
    print(unpack(args))
end

function helpers.dec2hex(value, padding)
    local base = 16
    local symbols = '0123456789ABCDEF'

    local output = ''

    local i = 0
    local d
    while value > 0 do
        i = i + 1
        value, d = math.floor(value / base), math.mod(value, base) + 1
        output = string.sub(symbols, d, d) .. output
    end

    -- pad result
    padding = padding or 4
    while output:len() < padding do
        output = '0' .. output
    end

    return output
end

return helpers
