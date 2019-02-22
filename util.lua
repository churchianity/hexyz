
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

local titlebutton =
[[
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
KwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KwkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkK
KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
]]

-- modified ethan shoonover solarized colortheme
am.ascii_color_map = {
    E = vec4( 22/255,  22/255,  29/255, 1), -- eigengrau

    K = vec4(  0,      43/255,  54/255, 1), -- dark navy
    k = vec4(  7/255,  54/255,  66/255, 1), -- navy
    L = vec4( 88/255, 110/255, 117/255, 1), -- gray1
    l = vec4(101/255, 123/255, 131/255, 1), -- gray2

    s = vec4(131/255, 148/255, 150/255, 1), -- gray3
    S = vec4(147/255, 161/255, 161/255, 1), -- gray4
    w = vec4(238/255, 232/255, 213/255, 1), -- bone
    W = vec4(253/255, 246/255, 227/255, 1), -- white

    y = vec4(181/255, 137/255,   0,     1), -- yellow
    o = vec4(203/255,  75/255,  22/255, 1), -- orange
    r = vec4(220/255,  50/255,  47/255, 1), -- red
    m = vec4(211/255,  54/255, 130/255, 1), -- magenta
    v = vec4(108/255, 113/255, 196/255, 1), -- violet
    b = vec4( 38/255, 139/255, 210/255, 1), -- blue
    c = vec4( 42/255, 161/255, 152/255, 1), -- cyan
    g = vec4(133/255, 153/255,   0,     1)  -- green
}
