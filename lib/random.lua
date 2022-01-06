
-- seed the random number generator with the current time
math.randomseed(os.clock())

-- https://stackoverflow.com/a/20177466/12464892
--local A1, A2 = 727595, 798405  -- 5^17=D20*A1+A2
--local D20, D40 = 1048576, 1099511627776  -- 2^20, 2^40
--local X1, X2 = 0, 1
--local function rand()
--    local U = X2*A2
--    local V = (X1*A2 + X2*A1) % D20
--    V = (V*D20 + U) % D40
--    X1 = math.floor(V/D20)
--    X2 = V - X1*D20
--    return V/D40
--end
--
--local SEED_BOUNDS = 2^20 - 1
--math.randomseed = function(seed)
--    local v = math.clamp(math.abs(seed), 0, SEED_BOUNDS)
--    X1 = v
--    X2 = v + 1
--end

-- to enable allowing the random number generator's state to be restored post-load (game-deserialize),
-- we count the number of times we call math.random(), and on deserialize, seed the random
-- number generator, and then discard |count| calls.
local R = math.random
RANDOM_CALLS_COUNT = 0
local function random(n, m)
    RANDOM_CALLS_COUNT = RANDOM_CALLS_COUNT + 1

    if n then
        if m then
            return R(n, m)
        else
            return R(n)
        end
    else
      return R()
    end
end

-- whenever we refer to math.random, actually use the function 'random' above
math.random = random

function g_octave_noise(x, y, num_octaves, seed)
    local seed = seed or os.clock()
    local noise = 0

    for oct = 1, num_octaves do
        local f = 1/4^oct
        local l = 2^oct
        local pos = vec2(x + seed, y + seed)
        noise = noise + f * math.simplex(pos * l)
    end

    return noise
end

---- @TODO test, fix
--function poisson_knuth(lambda)
--    local e = 2.71828
--
--    local L = e^-lambda
--    local k = 0
--    local p = 1
--
--    while p > L do
--        k = k + 1
--        p = p * math.random()
--    end
--
--    return k - 1
--end

