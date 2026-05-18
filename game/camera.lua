Camera = {}

function Camera:init()
    self.x = 0
    self.y = 0

    self.canvas = love.graphics.newCanvas(SCREEN.WIDTH, SCREEN.HEIGHT)
    self.canvas:setFilter("nearest", "nearest")

    self:recalculatePositionAndScale()
end


function Camera:recalculatePositionAndScale()
    local width, height = love.graphics.getDimensions()

    self.scale = math.max(1, math.min(
            math.floor(width / SCREEN.WIDTH),
            math.floor(height / SCREEN.HEIGHT)
    ))

    self.offset_x = (width - SCREEN.WIDTH * self.scale) / 2
    self.offset_y = (height - SCREEN.HEIGHT * self.scale) / 2
end


function Camera:worldToView(x, y)
    return x - self.x + SCREEN.WIDTH / 2, y - self.y + SCREEN.HEIGHT / 2
end


function Camera:viewToDisplay(x, y)
    return self.offset_x + x * self.scale, self.offset_y + y * self.scale
end


function Camera:draw()
    love.graphics.setColor(COLOR.WHITE)
    love.graphics.draw(self.canvas, self.offset_x, self.offset_y, 0, self.scale, self.scale)
end
