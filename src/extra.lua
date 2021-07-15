
function fprofile(f, ...)
    local t1 = am.current_time()
    local result = { f(...) }
    log("%f", am.current_time() - t1)
    return unpack(result)
end

function math.wrapf(float, range)
    return float - range * math.floor(float / range)
end

function math.lerp(v1, v2, t)
    return v1 * t + v2 * (1 - t)
end

-- don't use this with sparse arrays
function table.rchoice(t)
    return t[math.floor(math.random() * #t) + 1]
end

function table.count(t)
    local count = 0
    for i,v in pairs(t) do
        if v ~= nil then
            count = count + 1
        end
    end
    return count
end

function table.find(t, predicate)
    for i,v in pairs(t) do
        if predicate(v) then
            return i,v
        end
    end
    return nil
end

function quicksort(t, low_index, high_index, comparator)
    local function partition(t, low_index, high_index)
        local i = low_index - 1
        local pivot = t[high_index]

        for j = low_index, high_index - 1 do
            if comparator(t[j], t[pivot]) <= 0 then
                i = i + 1
                t[i], t[j] = t[j], t[i]
            end
        end

        t[i + 1], t[high_index] = t[high_index], t[i + 1]
        return i + 1
    end

    if #t == 1 then
        return t
    end

    if comparator(t[low_index], t[high_index]) < 0 then
        local partition_index = partition(t, low_index, high_index)

        quicksort(t, low_index, partition_index - 1, comparator)
        quicksort(t, partition_index + 1, high_index, comparator)
    end

    return t
end

