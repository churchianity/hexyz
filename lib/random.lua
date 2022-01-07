
RANDOM_CALLS_COUNT = 0

-- https://stackoverflow.com/a/32387452/12464892
local function bitwise_and(a, b)
    local result = 0
    local bit = 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then
            result = result + bit
        end
        bit = bit * 2       -- shift left
        a = math.floor(a/2) -- shift-right
        b = math.floor(b/2)
    end
    return result
end

-- https://stackoverflow.com/a/20177466/12464892
local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
local X1, X2 = 0, 1
local function rand()
    local U = X2*A2
    local V = (X1*A2 + X2*A1) % D20
    V = (V*D20 + U) % D40
    X1 = math.floor(V/D20)
    X2 = V - X1*D20
    return V/D40
end

local SEED_BOUNDS = 2^20 - 1
local function randomseed2(seed)
    -- 0 <= X1 <= 2^20-1, 1 <= X2 <= 2^20-1 (must be odd!)
    -- ensure the number is odd, and within bounds of the generator
    local seed = bitwise_and(seed, 1)
    local v = math.clamp(math.abs(seed), 0, SEED_BOUNDS)
    X1 = v
    X2 = v + 1
end

local RS = math.randomseed
math.randomseed = function(seed)
    RANDOM_CALLS_COUNT = 0
    RS(seed)
end

local R = math.random
local function random(n, m)
    RANDOM_CALLS_COUNT = RANDOM_CALLS_COUNT + 1

    local r
    if n then
        if m then
            r = R(n, m)
        else
            r = R(n)
        end
    else
        r = R()
    end

    return r
end

-- whenever we refer to math.random, actually use the function 'random' above
math.random = random

function g_octave_noise(x, y, num_octaves, seed)
    local seed = seed or os.time()
    local noise = 0

    for oct = 1, num_octaves do
        local f = 1/4^oct
        local l = 2^oct
        local pos = vec2(x + seed, y + seed)
        noise = noise + f * math.simplex(pos * l)
    end

    return noise
end

-- @TODO test, fix
function poisson_knuth(lambda)
    local e = 2.71828

    local L = e^-lambda
    local k = 0
    local p = 1

    while p > L do
        k = k + 1
        p = p * math.random()
    end

    return k - 1
end

-- seed the random number generator with the current time
-- os.clock() is better if the program has been running for a little bit.
math.randomseed(os.time())

