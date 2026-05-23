--[[

Устаревшая дока

Давайте поясню за физику ⚽

У нас есть Hitbox-ы, Rect-ы и Rigidbody.

Отдельно никакого класса Rigidbody нету, это скорее "интерфейс".
Rigidbody - это таблица, в которой есть поля x, y, velocity и hitbox.
Также можно добавить таблицу physics_settings, которая используется
в Physics.update().

Например, игрок это Rigidbody:

player = {
    x = 0,
    y = 0,
    velocity = { x = 0, y = 0 },
    hitbox = Hitbox:new(0, 0, 8, 8),
    physics_settings = {
        gravity = ...,
        friction = ...,
        min_horizontal_velocity = ...,
    },

    -- Ещё какие-то поля...
    -- ...
}

Про хитбоксы и прямоугольники можно почитать в `Hitbox.lua`

Основные функции: `move_x`, `move_y` Они двигают rigidbody в соответствие с
его velocity, а также следят за тем, чтобы у нас не было коллизий. Если же
коллизия была, то `move_x` и `move_y` вернут её (rigidbody все равно будет
корректно отпозиционирован (какое крутое слово)).

Также я добавил `update`, которая делает всё и сразу.

Для более низкоуровневых штук можно использовать другие функции. Основной
пример использования физики в игроке - заходите туда и копипастите код! 😁

Внимание: обрабатываются коллизии только с тайлами. Если мы хотим, например,
проверить столкновение двух панд между собой (то есть два динамических объекта),
то тут уж разбирайтесь сами. Низкоуровневые `check_collision_rect_rect` вам в
помощь.

--]]

Physics = {}

function Physics.init(Map)
    Physics.Map = Map
end


-- Проверяет, что прямо под хитбоксом что-то есть
function Physics.is_on_ground(position, hitbox)
    local collision = Physics.check_collision_rect_tilemap(
        Hitbox.to_rect(hitbox, position.x, position.y + 0.1)
    )
    return collision ~= nil, collision
end


function Physics.move_x(position, hitbox, delta)
    local next_x = position.x + delta

    local rect_after_x_move = Hitbox.to_rect(hitbox, next_x, position.y)

    local tilemap_collision = Physics.check_collision_rect_tilemap(rect_after_x_move)
    if tilemap_collision ~= nil then
        if tilemap_collision.glass then
            next_x = position.x
        else
            local left = next_x + hitbox.offset_x
            local right = left + hitbox.width
            if right > 8 + tilemap_collision.x and left < 8 + tilemap_collision.x then
                next_x = tilemap_collision.x + 8 - hitbox.offset_x
            else
                next_x = tilemap_collision.x - hitbox.width - hitbox.offset_x
            end
        end
    end

    position.x = next_x

    return tilemap_collision
end


function Physics.move_y(position, hitbox, delta)
    -- Обращаю внимание 🤓, что отрицательная velocity - полет вниз, в то время
    -- как ось y в TIC-80 перевернута, т.е. если мы хотим сдвинуть что-то
    -- **вниз** на 5, то мы делаем y = y + 5.
    --
    -- Отсюда минус в этой формуле (В move_x такого нет)
    local next_y = position.y - delta

    local rect_after_y_move = Hitbox.to_rect(hitbox, position.x, next_y)

    local tilemap_collision = Physics.check_collision_rect_tilemap(rect_after_y_move)
    if tilemap_collision ~= nil then
        if tilemap_collision.glass then
            next_y = position.y
        else
            local top = next_y + hitbox.offset_y
            local bottom = top + hitbox.height
            if bottom > 8 + tilemap_collision.y and top < 8 + tilemap_collision.y then
                next_y = tilemap_collision.y + 8 - hitbox.offset_y
            else
                next_y = tilemap_collision.y - hitbox.height - hitbox.offset_y
            end
        end
    end

    position.y = next_y

    return tilemap_collision
end

-- TODO: Уверен, в будущем нужно будет возвращать не только самое первое
-- столкновение, но вообще все столкновения, которые случились.
function Physics.check_collision_rect_tilemap(rect)
    assert(rect.w ~= 0)
    assert(rect.h ~= 0)

    local x = rect.x
    local y = rect.y
    local x2 = rect.x + rect.w - 1
    local y2 = rect.y + rect.h - 1

    local tile_x, tile_y = Map.worldToTile(x, y)

    local tile_x1, tile_y1 = Map.worldToTile(x, y)
    -- TODO: Без этого будет джиттер при толкании стены вправо. Надо
    -- подробнее на это посмотреть.
    local tile_x2 = math.floor((x2 + 0.99) / 8)
    local tile_y2 = math.floor((y2 + 0.99) / 8)

    function doesCollide(tx, ty)
        local id = Map.get(tx, ty)
        if id == 214 then
            local glassRect = Rect:new(8*tx, 8*ty, 1, 8)
            if Physics.check_collision_rect_rect(rect, glassRect) then
                return {
                    glass = true,
                    x = 8*tx,
                    y = 8*ty,
                }
            end
        elseif id == 215 then
            local glassRect = Rect:new(8*tx+7, 8*ty, 1, 8)
            if Physics.check_collision_rect_rect(rect, glassRect) then
                return {
                    glass = true,
                    x = 8*tx,
                    y = 8*ty,
                }
            end
        elseif Map.isSolid(tx, ty) then
            return {
                x = 8 * tx,
                y = 8 * ty,
            }
        end
        return nil
    end

    while y <= y2 do
        while x <= x2 do
            local collision = doesCollide(tile_x, tile_y)
            if collision then
                return collision
            end

            tile_x = tile_x + 1
            x = x + 8
        end

        y = y + 8
        tile_y = tile_y + 1
        x = rect.x
        tile_x = Map.worldToTileX(x)
    end

    local collision = doesCollide(tile_x2, tile_y1)
    if collision then
        return collision
    end

    local collision = doesCollide(tile_x1, tile_y2)
    if collision then
        return collision
    end

    local collision = doesCollide(tile_x2, tile_y2)
    if collision then
        return collision
    end

    return nil
end


function Physics.check_collision_rect_rect(r1, r2)
    if r1:left() > r2:right() or
       r2:left() > r1:right() or
       r1:top() > r2:bottom() or
       r2:top() > r1:bottom() then
        return false
    end
    return true
end


function Physics.try_to_unstuck_rigidbody(position, hitbox)
    local current_rect = Hitbox.to_rect(hitbox, position.x, position.y)

    local originalPositionX = position.x + hitbox.offset_x
    local originalPositionY = position.y + hitbox.offset_y

    local new_rect = current_rect

    local bestDistance = 10000
    local bestX = -1000
    local bestY = -1000

    local radius = 1
    while radius < 10 do
        for dy = -radius, radius do
            new_rect.x = originalPositionX - radius
            new_rect.y = originalPositionY + dy
            if Physics.check_collision_rect_tilemap(new_rect) == nil then
                local distance = lume.distance(new_rect.x, new_rect.y, originalPositionX, originalPositionY)
                if bestDistance > distance then
                    bestDistance = distance
                    bestX = new_rect.x
                    bestY = new_rect.y
                end
            end

            new_rect.x = originalPositionX + radius
            new_rect.y = originalPositionY + dy
            if Physics.check_collision_rect_tilemap(new_rect) == nil then
                local distance = lume.distance(new_rect.x, new_rect.y, originalPositionX, originalPositionY)
                if bestDistance > distance then
                    bestDistance = distance
                    bestX = new_rect.x
                    bestY = new_rect.y
                end
            end
        end

        for dx = -radius + 1, radius - 1 do
            new_rect.x = originalPositionX + dx
            new_rect.y = originalPositionY - radius
            if Physics.check_collision_rect_tilemap(new_rect) == nil then
                local distance = lume.distance(new_rect.x, new_rect.y, originalPositionX, originalPositionY)
                if bestDistance > distance then
                    bestDistance = distance
                    bestX = new_rect.x
                    bestY = new_rect.y
                end
            end

            new_rect.x = originalPositionX + dx
            new_rect.y = originalPositionY + radius
            if Physics.check_collision_rect_tilemap(new_rect) == nil then
                local distance = lume.distance(new_rect.x, new_rect.y, originalPositionX, originalPositionY)
                if bestDistance > distance then
                    bestDistance = distance
                    bestX = new_rect.x
                    bestY = new_rect.y
                end
            end
        end

        radius = radius + 1

        if bestDistance < 10000 then
            break
        end
    end

    if bestX == -1000 or bestY == -1000 then
        -- Это безнадёга. Проверили квадрат размером в 4 тайла -- никуда не
        -- помещается. Тут только менять уровень или же это смертельный баг.
        lume.trace("SOMEONE IS STUCK TO DEATH AT " .. position.x .. ", " .. position.y .. " FOREVER...")
    else
        lume.trace('Unstuck from ', position.x, position.y, ' to ', bestX, bestY, 'distance', bestDistance)
        position.x = bestX
        position.y = bestY
    end
end
