Screen = {}

function Screen:init(width, height)
    self.width = width
    self.height = height

    self.canvas = love.graphics.newCanvas(self.width, self.height)
    self.canvas:setFilter("nearest", "nearest")

    self:recalculatePositionAndScale()
end


function Screen:recalculatePositionAndScale()
    local width, height = love.graphics.getDimensions()

    self.scale = math.max(1, math.min(
            math.floor(width / self.width),
            math.floor(height / self.height)
    ))

    self.offset_x = (width - SCREEN.WIDTH * self.scale) / 2
    self.offset_y = (height - SCREEN.HEIGHT * self.scale) / 2
end


function Screen:toReal(x, y)
    return self.offset_x + x * self.scale, self.offset_y + y * self.scale
end
