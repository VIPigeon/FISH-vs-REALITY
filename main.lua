-- Рыба 🐟

lume   = require('libs.lume')
lurker = require('libs.lurker')

require('base.common')
require('base.input')
require('base.pool')
require('base.rect')
require('base.screen')
require('base.hitbox')

require('game.data')
require('game.entity')
require('game.game')
require('game.map')
require('game.physics')


function love.load()
    love.window.updateMode(0, 0, {resizable = true, vsync = true, minwidth = SCREEN.WIDTH, minheight = SCREEN.HEIGHT})

    Game:init()
end


function love.update()
    --lurker.update()

    Input.update()
    Game:update()

    love.graphics.setCanvas(Screen.canvas)
    Game:draw()
    love.graphics.setCanvas()
end


function love.draw()
    love.graphics.clear(COLOR.BLACK)

    love.graphics.setColor(COLOR.WHITE)
    love.graphics.draw(Screen.canvas, Screen.offset_x, Screen.offset_y, 0, Screen.scale, Screen.scale)

    -- Дебажная информация.
    -- Хорошо что мы не ограничены маленьким экраном Тика для этих целей!
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()))
    love.graphics.print("EntityPool: " .. Game.entityPool:count() .. '/' .. Game.entityPool:capacity(), 0, 16)
    Game.entityPool:foreach(function(e, ref)
        if e.position then
            love.graphics.print(lume.format("({1} {2})", {math.floor(e.position.x), math.floor(e.position.y)}), Screen:toReal(e.position.x, e.position.y))
        end

        --if e.hitbox then
        --    local x, y = Screen:toReal(e.position.x + e.hitbox.offset_x, e.position.y + e.hitbox.offset_y)
        --    local w = Screen.scale * e.hitbox.width
        --    local h = Screen.scale * e.hitbox.height
        --    love.graphics.setColor(COLOR.WHITE)
        --    love.graphics.rectangle('fill', x, y, w, h)
        --end
    end)
end


function love.resize(_w, _h)
    Screen:recalculatePositionAndScale()
end


function love.mousepressed(x, y, button, istouch)
    -- Конвертируем координаты мышки в координаты на нашем маленьком экране
    x = x - Screen.offset_x
    y = y - Screen.offset_y
    x = x / Screen.scale
    y = y / Screen.scale

    -- А дальше пока что ничего...
end


function love.keypressed(key, scancode, isrepeat)
   if key == "escape" then
       love.event.quit()
   end
end
