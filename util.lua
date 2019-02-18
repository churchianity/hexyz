
function rhue(a)
    local R = math.random(35, 75) / 100
    local G = math.random(35, 75) / 100
    local B = math.random(35, 75) / 100
    local A = a or math.random()

    return vec4(R, G, B, A)
end

function rmono()
    return vec4(1, 1, 1, math.random())
end
