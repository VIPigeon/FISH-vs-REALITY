
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
        local frame_x = 0
        while frame_x * grid_x < width do
            local x = frame_x * grid_x
            local y = frame_y * grid_y
            local map = {}
            local new_rect = {}

            -- ищем левый верхний угол
            for x = frame_x * grid_x, (frame_x+1) * grid_x - 1 do
                table.insert(map, {})
                for y = frame_y * grid_y, (frame_y+1) * grid_y - 1 do
                    local r, g, b, a = imageData:getPixel(x, y)
                    local is_special = (r == special_color.r and g == special_color.g and b == special_color.b)
                    table.insert(map[#map], is_special)

                    local local_x = x % grid_x + 1
                    local local_y = y % grid_y + 1
                    if is_special and (x == 0 or not map[local_y][local_x-1]) and (y == 0 or not map[local_y-1][local_x]) then
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

                    if is_special and (x == grid_x-1 or not map[local_y][local_x+1]) and (y == grid_y-1 or not map[local_y+1][local_x]) then
                        -- это правый нижний угол ВКЛЮЧИТЕЛЬНО
                        new_rect.x2 = local_x - 1
                        new_rect.y2 = local_y - 1
                        goto continue
                    end
                end
            end
            ::continue::
            table.insert(rects, new_rect)
            frame_x = frame_x + 1
        end

        frame_y = frame_y + 1
    end

    return rects
end
