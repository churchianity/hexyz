
-- utility functions that don't below elsewhere go here,
-- especially if they would be at home on the global 'math' or 'table' variables, or are otherwise extensions of standard lua features
-- try to avoid *too* much amulet specific stuff, but vector types are probably ok.

function fprofile(f, ...)
    local t1 = am.current_time()
    local result = { f(...) }
    local time = am.current_time() - t1
    --log("%f", time)
    return time, unpack(result)
end

function math.wrapf(float, range)
    return float - range * math.floor(float / range)
end

function math.lerp(v1, v2, t)
    return v1 * t + v2 * (1 - t)
end

-- manually found the smallest number, doesn't make sense to me why, but hey it's one less than a power of two which is probably significant
-- pretty sure IEEE-754's smallest value is less than this, 32bit or 64bit
math.SMALLEST_NUMBER_ABOVE_0 = 2 ^ (-1023)

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

function table.highest_index(t)
    local highest = nil
    for i,v in pairs(t) do
        if i and not highest then
            highest = i
        end

        if i > highest then
            highest = i
        end
    end
    return highest
end

function table.find(t, predicate)
    for i,v in pairs(t) do
        if predicate(v) then
            return i,v
        end
    end
    return nil
end

-- don't use with sparse arrays or hash tables.
-- only arrays.
-- mutates the array in place.
function table.reverse(t)
    local n = #t
    for i,v in pairs(t) do
        t[i], t[n] = t[n], t[i]
        n = n - 1
    end
end

function table.quicksort(t, low_index, high_index, comparator)
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

