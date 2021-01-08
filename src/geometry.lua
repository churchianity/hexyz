

function circles_intersect(center1, center2, radius1, radius2)
    return (((center1.x - center2.x)^2 + (center1.y - center2.y)^2)^0.5) <= (radius1 + radius2)
end

function point_in_rect(point, rect)
    return point.x > rect.x1
       and point.x < rect.x2
       and point.y > rect.y1
       and point.y < rect.y2
end

