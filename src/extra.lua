

function math.wrapf(float, range)
    return float - range * math.floor(float / range)
end

function math.lerp(v1, v2, t)
    return v1 * t + v2 * (1 - t)
end

function table.rchoice(t)
    return t[math.floor(math.random() * #t) + 1]
end

function table.find(t, predicate)
    for i,v in pairs(t) do
        if predicate(v) then
            return i,v
        end
    end
    return nil
end
