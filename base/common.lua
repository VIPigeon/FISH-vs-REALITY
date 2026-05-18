-- Взял из:
-- https://gist.github.com/tylerneylon/81333721109155b2d244
--
-- This functions works well for simple tables. Since it is a
-- clear, concise function, and since I most often work with
-- simple tables, this is my favorite version.
--
-- There are two aspects this does not handle:
-- * metatables
-- * recursive tables
function table.deepcopy(object)
    if type(object) ~= 'table' then
        return object
    end

    local result = {}
    for k, v in pairs(object) do
        result[table.deepcopy(k)] = table.deepcopy(v)
    end
    return result
end

function table.contains(t, element)
    for _, value in pairs(t) do
        if value == element then
            return true
        end
    end
    return false
end

Time = {}
function Time.tick(timer)
    local deltaTime = love.timer.getDelta()
    return math.max(timer - deltaTime, 0.0)
end

function math.random_float(min, max)
    return min + math.random() * (max - min)
end


function table.shuffle(t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end