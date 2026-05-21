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

   if key == 'f' then
       if LOCKED_FPS == 60 then
           LOCKED_FPS = 165
       else
           LOCKED_FPS = 60
       end
       SINGLE_FRAME_DURATION = 1 / LOCKED_FPS
   end

end

-- ❗ ВАЖНО (но не знаю для кого)
--
-- Нормальным людям love.run переопределять не нужно. Но у нас PANDA KILLER.
--
-- Очень удобно, что в игре мы никогда не используем deltaTime при вычислениях.
-- Действительно, зачем волноваться о таким мелочах как независимость от скорости
-- кадров? В TIC-80 у нас всегда 60 FPS!
--
-- И вот я перенес все на love, и он с VSync выдает мне 165 FPS-ов. Игра стала
-- в два с половиной раза быстрее. Встроенного способа поставить лимит FPS нету,
-- поэтому я взял стандартную реализацию из https://love2d.org/wiki/love.run,
-- и добавил sleep в конец. Грязно, но проблему решает. Но тогда разве это грязно?
-- Решил конкретную проблему самым прямолинейным способом, не выдумывая какие-то
-- сложные системы или обходы, а просто добавив парочку строчек кода. Думайте.
LOCKED_FPS = 165
SINGLE_FRAME_DURATION = 1 / LOCKED_FPS

function love.run()
    if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    return function()
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a or 0
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end

        -- Update dt, as we'll be passing it to update
        if love.timer then
            global_frame_start = love.timer.getTime()
            dt = love.timer.step()
        end

        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

        if love.graphics and love.graphics.isActive() then
            love.graphics.origin()
            love.graphics.clear(love.graphics.getBackgroundColor())

            if love.draw then love.draw() end

            love.graphics.present()
        end

        if love.timer then
            local frame_end = love.timer.getTime()
            if frame_end - global_frame_start < SINGLE_FRAME_DURATION then
                love.timer.sleep(global_frame_start + SINGLE_FRAME_DURATION - frame_end)
            end
        end
    end
end

