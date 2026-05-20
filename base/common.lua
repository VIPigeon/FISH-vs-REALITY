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
    -- Handle non-tables and previously-seen tables.
    if type(object) ~= 'table' then
        return object
    end

    if seen and seen[object] then
        return seen[object]
    end

    -- New table; mark it as seen and copy recursively.
    local s = seen or {}
    local res = {}
    s[object] = res
    for k, v in pairs(object) do
        res[table.deepcopy(k, s)] = table.deepcopy(v, s)
    end
    return setmetatable(res, getmetatable(object))
end

function table.copy(t)
    result = {}
    for k, v in pairs(t) do
        result[k] = v
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

-- Функции ниже даже без неймспейса.
-- Потому что я больше физически не могу
-- писать все эти дурацкие префиксы. Во
-- мне бунтует Сишник.

function isUpper(s)
    -- Ну что, кто скажет что это неправильно? Никто!
    -- Значит правильно.
    return string.lower(s) ~= s
end

function moduloIncrement(x, mod)
    x = x + 1
    if x > mod then
        x = 1
    end
    return x
end

-- Настоящий пример Open Closed Principle в действии!
-- Вот это дизайн!
function string:char(index)
    return self:sub(index, index)
end

function string:equalIgnoreCase(s)
    return string.lower(self) == string.lower(s)
end
