-- Рыба 🐟

lume   = require('libs.lume')
lurker = require('libs.lurker')
anim8  = require('libs.anim8')

require('base.common')
require('base.input')
require('base.pool')
require('base.rect')
require('base.hitbox')
require('base.timer')
require('base.box_map')

require('game.camera')
require('game.data')
require('game.game')
require('game.map')
require('game.physics')


function love.load()
    love.window.updateMode(0, 0, {resizable = true, vsync = true, minwidth = SCREEN.WIDTH, minheight = SCREEN.HEIGHT})
    love.graphics.setDefaultFilter('nearest', 'nearest', 1)

    local font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    Game:init()
end


function love.update()
    --lurker.update()

    Input.update()
    Game:update()
end


function love.draw()
    Game:draw()

    love.graphics.clear(COLOR.BLACK)

    Camera:draw()

    -- Дебажная информация.
    -- Хорошо что мы не ограничены маленьким экраном Тика для этих целей!
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 0, 0)
    love.graphics.print("'g' - godmode 'h' - hitboxes", 0, 22)
    if Game.debug.godmode then
        love.graphics.print("GODMODE enabled", 0, 44)
    end
    if Game.debug.showHitbox then
        Game.entityPool:foreach(function(e, ref)
            if e.hitbox then
                local x, y = Camera:worldToView(e.position.x + e.hitbox.offset_x, e.position.y + e.hitbox.offset_y)
                local dx, dy = Camera:viewToDisplay(x, y)
                local w, h = e.hitbox.width * Camera.scale, e.hitbox.height * Camera.scale
                love.graphics.rectangle('line', dx, dy, w, h)
            end

            if e.player then
                local cx = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
                local cy = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
                local x, y = e.position.x + e.hitbox.offset_x, e.position.y + e.hitbox.offset_y
                local dx, dy = Camera:worldToDisplay(cx, cy)
                love.graphics.print(string.format('%d %d', x, y), dx, dy)
            end
        end)
    end
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

   if key == 'r' then
       Game:restart()
   end

   if key == 'g' then
       Game.debug.godmode = not Game.debug.godmode
   end

   if key == 'h' then
       Game.debug.showHitbox = not Game.debug.showHitbox
   end
end
