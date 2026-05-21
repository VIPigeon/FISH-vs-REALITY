Camera = {}

function Camera:init()
    self.x = 0
    self.y = 0

    self.smoothing = CAMERA.SMOOTHING
    self.dead_zone = {
        x = CAMERA.DEAD_ZONE_X,
        y = CAMERA.DEAD_ZONE_Y,
    }

    self.offset_x = 0
    self.offset_y = 0

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
    return x - self.x, y - self.y
end

function Camera:viewToDisplay(x, y)
    return self.offset_x + x * self.scale, self.offset_y + y * self.scale
end

function Camera:worldToDisplay(x, y)
    local viewX, viewY = self:worldToView(x, y)
    return self:viewToDisplay(viewX, viewY)
end


function Camera:update(target, dt)
    local desiredX = target.x - SCREEN.WIDTH/2
    local desiredY = target.y - SCREEN.HEIGHT/2

    local dx = desiredX - self.x
    local dy = desiredY - self.y
    if math.abs(dx) > self.dead_zone.x then
        desiredX = self.x + (dx - lume.sign(dx) * self.dead_zone.x)
    else
        desiredX = self.x
    end
    if math.abs(dy) > self.dead_zone.y then
        desiredY = self.y + (dy - lume.sign(dy) * self.dead_zone.y)
    else
        desiredY = self.y
    end

    self.x = self.x + (desiredX - self.x) * self.smoothing
    self.y = self.y + (desiredY - self.y) * self.smoothing
end


function Camera:beginDraw()
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(COLOR.GAMEBOY.BACKGROUND)
    love.graphics.setColor(COLOR.WHITE)
    
    love.graphics.push()
    love.graphics.translate(-self.x, -self.y)
end


function Camera:endDraw()
    love.graphics.pop()
    love.graphics.setCanvas()
end


function Camera:draw()
    love.graphics.setColor(COLOR.WHITE)
    love.graphics.draw(self.canvas, self.offset_x, self.offset_y, 0, self.scale, self.scale)
end
