-- Рыба 🐟

lume   = require('libs.lume')
lurker = require('libs.lurker')
anim8  = require('libs.anim8')

require('base.common')
require('base.input')
require('base.pool')
require('base.rect')
require('base.hitbox')

require('game.camera')
require('game.data')
require('game.game')
require('game.map')
require('game.physics')


function love.load()
    love.window.updateMode(0, 0, {resizable = true, vsync = true, minwidth = SCREEN.WIDTH, minheight = SCREEN.HEIGHT})
    love.graphics.setDefaultFilter('nearest', 'nearest', 1)

    Game:init()
end


function love.update()
    --lurker.update()

    Input.update()
    Game:update()
end


function love.draw()
    love.graphics.setCanvas(Camera.canvas)
    Game:draw()
    love.graphics.setCanvas()

    love.graphics.clear(COLOR.BLACK)

    Camera:draw()

    -- Дебажная информация.
    -- Хорошо что мы не ограничены маленьким экраном Тика для этих целей!
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()))
end


function love.resize(_w, _h)
    Camera:recalculatePositionAndScale()
end


function love.mousepressed(x, y, button, istouch)
    -- Конвертируем координаты мышки в координаты на нашем маленьком экране
    x = x - Camera.offset_x
    y = y - Camera.offset_y
    x = x / Camera.scale
    y = y / Camera.scale

    -- А дальше пока что ничего...
end


function love.keypressed(key, scancode, isrepeat)
   if key == "escape" then
       love.event.quit()
   end
end
