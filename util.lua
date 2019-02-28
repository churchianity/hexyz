
function terr(a)
    local R = math.random(35, 75) / 100
    local G = math.random(35, 75) / 100
    local B = math.random(35, 75) / 100
    local A = a or math.random()

    return vec4(R, G, B, A)
end

function rmono()
    return vec4(1, 1, 1, math.random())
end

function show_axes()
    local xaxis = am.line(vec2(win.left, 0), vec2(win.right, 0))
    local yaxis = am.line(vec2(0, win.top), vec2(0, win.bottom))
    win.scene:append(am.translate(0, 0) ^ am.group{xaxis, yaxis}:tag"axes")
end


