

function circles_intersect(center1, center2, radius1, radius2)
    local c1, c2, r1, r2 = center1, center2, radius1, radius2
    local d = math.distance(center1, center2)
    local radii_sum = r1 + r2
                                    -- touching
    if d == radii_sum then          return 1

                                    -- not touching or intersecting
    elseif d > radii_sum then       return false

                                    -- intersecting
    else                            return 2
    end
end

function point_in_rect(point, rect)
    return point.x > rect.x1
       and point.x < rect.x2
       and point.y > rect.y1
       and point.y < rect.y2
end

