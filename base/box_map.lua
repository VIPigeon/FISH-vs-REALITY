
box_map = {}

function box_map.get_boxes_from_image(path, special_color, grid_x, grid_y)
    -- 'fff491'
    special_color = special_color or {r=16*15+15, g=16*15+4, b=16*9+1}
    grid_x = grid_x or 16
    grid_y = grid_y or 16

    local imageData = love.image.newImageData(path)

    local width = imageData:getWidth()
    local height = imageData:getHeight()

    local rects = {}

    local frame_y = 0
    while frame_y * grid_y < height do
        table.insert(rects, {})
        local frame_x = 0
        while frame_x * grid_x < width do
            local map = {}
            local new_rect = {}

            -- ищем левый верхний угол
            for y = frame_y * grid_y, (frame_y+1) * grid_y - 1 do
                table.insert(map, {})
                for x = frame_x * grid_x, (frame_x+1) * grid_x - 1 do
                    local r, g, b, a = imageData:getPixel(x, y)
                    r = math.floor(r * 255 + 0.5)
                    g = math.floor(g * 255 + 0.5)
                    b = math.floor(b * 255 + 0.5)
                    -- print(r, g, b)
                    local is_special = (r == special_color.r and g == special_color.g and b == special_color.b)
                    table.insert(map[#map], is_special)

                    local local_x = x % grid_x + 1
                    local local_y = y % grid_y + 1
                    -- print(local_x, local_y)
                    -- if local_x ~= 1 and local_y ~= 1 then
                    --     print(map[local_y][local_x-1], map[local_y-1][local_x])
                    -- end
                    
                    if is_special and (local_x == 1 or not map[local_y][local_x-1]) and (local_y == 1 or not map[local_y-1][local_x]) then
                        -- это левый верхний угол
                        new_rect.x1 = local_x - 1
                        new_rect.y1 = local_y - 1
                    end
                end
            end

            -- ищем правый нижний угол
            for x = (frame_x+1) * grid_x - 1, frame_x * grid_x, -1 do
                for y = (frame_y+1) * grid_y - 1, frame_y * grid_y, -1 do
                    local local_x = x % grid_x + 1
                    local local_y = y % grid_y + 1
                    local is_special = map[local_y][local_x]

                    if is_special and (local_x == grid_x-1 or not map[local_y][local_x+1]) and (local_y == grid_y-1 or not map[local_y+1][local_x]) then
                        -- это правый нижний угол ВКЛЮЧИТЕЛЬНО
                        new_rect.x2 = local_x - 1
                        new_rect.y2 = local_y - 1
                        goto continue
                    end
                end
            end
            ::continue::
            -- print(new_rect.x1, new_rect.x2, new_rect.y1, new_rect.y2)
            table.insert(rects[#rects], new_rect)
            frame_x = frame_x + 1
        end

        frame_y = frame_y + 1
    end

    -- rects[y][x] дает rect по фрейму
    return rects
end

-- устанавливает сущности компонент hitbox
function box_map.to_hitbox(box)
    -- local x1 = box_by_frame[frame_x][frame_y].x1
    -- local y1 = box_by_frame[frame_x][frame_y].y1
    -- local x2 = box_by_frame[frame_x][frame_y].x2
    -- local y2 = box_by_frame[frame_x][frame_y].y2
    local x1 = box.x1
    local y1 = box.y1
    local x2 = box.x2
    local y2 = box.y2
    local hitbox = {
        offset_x = x1,
        offset_y = y1,
        width = x2 - x1 + 1,
        height = y2 - y1 + 1,
    }
    return hitbox
end
