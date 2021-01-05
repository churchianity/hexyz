
function math.wrapf(float, range)
    return float - range * math.floor(float / range)
end

function math.lerpv2(v1, v2, t)
    return v1 * t + v2 * (1 - t)
end

