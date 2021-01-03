
function table.shift(t, count)
    local e = t[1]
    t[1] = nil

    for i,e in pairs(t) do
        if e then
            t[i - 1] = e
        end
    end

    return e
end

