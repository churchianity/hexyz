
function rrgb(a)
    local R = math.random(20, 80) / 100
    local G = math.random(20, 80) / 100
    local B = math.random(20, 80) / 100
    local A = a or math.random()

    return vec4(R, G, B, A)
end
