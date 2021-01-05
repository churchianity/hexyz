
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

