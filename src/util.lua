
function twoD_get(t, x, y)
    return t[x] and t[x][y]
end

function twoD_set(t, x, y, v)
    if t[x] then
        t[x][y] = v
    else
        t[x] = {}
        t[x][y] = v
    end
end

