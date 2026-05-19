Game = {}

function Game:init()
    -- Находится в Data
    ASSETS:loadAll()

    Camera:init()
    Input.init()
    Map.init(ASSETS.tilemap)

    self.debug = {
        godmode = false,
        shotHitboxes = false,
    }

    self:restart()
end


function Game:createDefaultPlayer()
    local player = {
        position = {
            x = PLAYER.SPAWN_X,
            y = PLAYER.SPAWN_Y,
        },
        rectangle = {
            width = 8,
            height = 8,
        },
        player = {
            oxygen = PLAYER.OXYGEN,
            jump = {
                -- багоопасно. копирование по ссылке. ебануть не должно
                bucket = PLAYER.JUMP.BUCKET,
                i = 1,
                t = 0,
            },
        },
        rigidbody = {
            velocity = {
                x = 0,
                y = 0,
            },
            acceleration = {
                x = 0,
                y = 0,
            },
        },
        hitbox = {
            offset_x = 0,
            offset_y = 0,
            width = 8,
            height = 8,
        },
    }

    local jump_type = player.player.jump.bucket[1]
    player.player.jump.t = PLAYER.JUMP[jump_type].T
    table.shuffle(player.player.jump.bucket)

    return player
end

function Game:restart()
    math.randomseed(os.time()*1e7)

    self.entityPool = Pool:new()
    self.handles = {} -- Тут лежат ссылки на entities, если к ним нужен доступ
                      -- Handles это прикольная тема, можно почитать тут:
                      -- https://floooh.github.io/2018/06/17/handles-vs-pointers.html

    local player = Game:createDefaultPlayer()

    local jelly = {
        position = { x = 32, y = 80 },
        rigidbody = {
            velocity = { x = 0, y = 0 },
            acceleration = { x = 0, y = 0 },
        },
        hitbox = {
            offset_x = 0,
            offset_y = 0,
            width = 8,
            height = 8,
        },
        sprite = {
            animation = 1, -- Индекс текущей анимации
            animations = {
                ASSETS.jellyIdleAnimation:clone(),
                ASSETS.jellyPrepareAnimation:clone(),
                ASSETS.jellyDashAnimation:clone(),
            },
            spritesheet = ASSETS.jellySpritesheet,
        },
        jelly = {
            program = '..d..r..u....l',
            programTimer = Timer:new(JELLY.TICK_FREQUENCY),
            programIndex = 1,
        },
    }

    local jelly2 = table.deepcopy(jelly)
    jelly2.position.x = 240
    jelly2.position.y = 80
    jelly2.jelly.program = '..r'

    local checkpointSprite = {
        animation = 1,
        animations = {
            ASSETS.checkpointDisabledAnimation:clone(),
            ASSETS.checkpointActiveAnimation:clone(),
        },
        spritesheet = ASSETS.checkpointSpritesheet,
    }
    local checkpoints = {
        {
            position = { x = 96, y = 56, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 176, y = 40, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 248, y = 40, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
    }

    for _, checkpoint in ipairs(checkpoints) do
        self.entityPool:put(checkpoint)
    end
    self.entityPool:put(jelly)
    self.entityPool:put(jelly2)
    self.handles.player = self.entityPool:put(player)
end


function Game:respawnPlayer()
    -- Находим самый правый чекпоинт
    local respawnX, respawnY = PLAYER.SPAWN_X, PLAYER.SPAWN_Y
    self.entityPool:foreach(function(e, ref)
        if e.checkpoint and e.checkpoint.active then
            if e.position.x > respawnX then
                respawnX = e.position.x
                respawnY = e.position.y
            end
        end
    end)

    local newPlayer = Game:createDefaultPlayer()
    newPlayer.position.x = respawnX
    newPlayer.position.y = respawnY
    self.entityPool:delete(self.handles.player)
    self.handles.player = self.entityPool:put(newPlayer)
end


function Game:update()
    local deltaTime = love.timer.getDelta()

    self.entityPool:foreach(function(e, ref)
        local tile = 0
        if e.position and e.hitbox then
            local centerX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            local centerY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            tile = Map.get(Map.worldToTile(centerX, centerY))
        end

        if e.checkpoint then
            local player = self.entityPool:get(self.handles.player)
            if player.position.x > e.position.x then
                e.checkpoint.active = true
                e.sprite.animation = 2
            end
        end

        if e.player then
            if Map.isWater(tile) then
                e.player.oxygen = math.min(PLAYER.OXYGEN, e.player.oxygen + deltaTime*PLAYER.OXYGEN_INCOME)
            else
                e.player.oxygen = Time.tick(e.player.oxygen)
            end

            if self.debug.godmode then
                e.player.oxygen = PLAYER.OXYGEN
            end
        end

        if e.player then
            if e.player.oxygen <= 0 then
                Game:respawnPlayer()
            end

            if self.debug.godmode or Map.isWater(tile) then
                e.rigidbody.acceleration.y = 0
                if Input.isDown(KEYBINDS.ACTION_UP) then
                    e.rigidbody.acceleration.y = e.rigidbody.acceleration.y + PLAYER.WATER_ACCELERATION
                end
                if Input.isDown(KEYBINDS.ACTION_DOWN) then
                    e.rigidbody.acceleration.y = e.rigidbody.acceleration.y - PLAYER.WATER_ACCELERATION
                end

                e.rigidbody.acceleration.x = 0
                if Input.isDown(KEYBINDS.ACTION_LEFT) then
                    e.rigidbody.acceleration.x = e.rigidbody.acceleration.x - PLAYER.WATER_ACCELERATION
                end
                if Input.isDown(KEYBINDS.ACTION_RIGHT) then
                    e.rigidbody.acceleration.x = e.rigidbody.acceleration.x + PLAYER.WATER_ACCELERATION
                end

                if e.rigidbody.acceleration.x ~= 0 and e.rigidbody.acceleration.y ~= 0 then
                    assert(math.abs(e.rigidbody.acceleration.x) == math.abs(e.rigidbody.acceleration.y))
                    e.rigidbody.acceleration.x = e.rigidbody.acceleration.x / math.sqrt(2)
                    e.rigidbody.acceleration.y = e.rigidbody.acceleration.y / math.sqrt(2)
                end
            else
                e.rigidbody.acceleration.x = 0
                e.rigidbody.acceleration.y = 0

                -- if Input.isJustPressed(KEYBINDS.JUMP) then
                --     e.rigidbody.acceleration.y = 10000
                -- end

                local onGround = Physics.is_on_ground(e.position, e.hitbox)
                if onGround then -- автопрыжок только на земле
                    e.player.jump.t = Time.tick(e.player.jump.t)
                    if e.player.jump.t == 0 then
                        -- прыжок
                        local jump_type = e.player.jump.bucket[e.player.jump.i]
                        e.rigidbody.velocity.y = PLAYER.JUMP[jump_type].F

                        if jump_type == 'high' then
                            table.shuffle(e.player.jump.bucket)
                            e.player.jump.i = 1
                        else
                            e.player.jump.i = e.player.jump.i + 1
                            -- таймер на следующий прыжок
                        end
                        jump_type = e.player.jump.bucket[e.player.jump.i]
                        e.player.jump.t = PLAYER.JUMP[jump_type].T
                    end
                else -- горизонтальное перемещение только в воздухе
                    if Input.isDown(KEYBINDS.ACTION_LEFT) then
                        e.rigidbody.acceleration.x = e.rigidbody.acceleration.x - PLAYER.GROUND_ACCELERATION
                    end

                    if Input.isDown(KEYBINDS.ACTION_RIGHT) then
                        e.rigidbody.acceleration.x = e.rigidbody.acceleration.x + PLAYER.GROUND_ACCELERATION
                    end

                end
            end
        end

        if e.rigidbody then
            if (e.player and self.debug.godmode) or Map.isWater(tile) then
                local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
                if collisionX ~= nil then
                    if math.abs(e.rigidbody.velocity.x) < 75 then
                        e.rigidbody.velocity.x = -1 * e.rigidbody.velocity.x
                    else
                        e.rigidbody.velocity.x = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.x
                    end
                end

                local collisionY = Physics.move_y(e.position, e.hitbox, e.rigidbody.velocity.y * deltaTime)
                if collisionY ~= nil then
                    e.rigidbody.velocity.y = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.y
                end

                if e.rigidbody.acceleration.x == 0 then
                    e.rigidbody.velocity.x = e.rigidbody.velocity.x * WORLD.WATER_FRICTION
                    if math.abs(e.rigidbody.velocity.x) < 1 then
                        e.rigidbody.velocity.x = 0
                    end
                end

                if e.rigidbody.acceleration.y == 0 then
                    e.rigidbody.velocity.y = e.rigidbody.velocity.y * WORLD.WATER_FRICTION
                    if math.abs(e.rigidbody.velocity.y) < 1 then
                        e.rigidbody.velocity.y = 0
                    end
                end

                e.rigidbody.velocity.x = e.rigidbody.velocity.x + e.rigidbody.acceleration.x * deltaTime
                e.rigidbody.velocity.y = e.rigidbody.velocity.y + e.rigidbody.acceleration.y * deltaTime
            else
                local vel = e.rigidbody.acceleration.y
                if not onGround then
                    vel = vel - GRAVITY
                end
                e.rigidbody.velocity.y = e.rigidbody.velocity.y + vel * 0.5 * deltaTime

                local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
                if collisionX ~= nil then
                    -- e.rigidbody.velocity.x = 0                    
                    if math.abs(e.rigidbody.velocity.x) < 75 then
                        local v = e.rigidbody.velocity.x
                        local V = PLAYER.MIN_V_FOR_BOUNCE
                        if e.rigidbody.velocity.x > 0 then
                            v = math.max(v, V)
                        else
                            v = math.min(v, -V)
                        end
                        e.rigidbody.velocity.x = -1 * v
                    else
                        e.rigidbody.velocity.x = -1 * PLAYER.WALL_BOUNCE * e.rigidbody.velocity.x
                    end
                end

                local collisionY = Physics.move_y(e.position, e.hitbox, e.rigidbody.velocity.y * deltaTime)
                if collisionY ~= nil then
                    e.rigidbody.velocity.y = 0
                end

                local onGround = Physics.is_on_ground(e.position, e.hitbox)

                if e.rigidbody.acceleration.x == 0 and onGround then
                    e.rigidbody.velocity.x = e.rigidbody.velocity.x * WORLD.GROUND_FRICTION
                    if math.abs(e.rigidbody.velocity.x) < 1 then
                        e.rigidbody.velocity.x = 0
                    end
                end

                if onGround and e.rigidbody.acceleration.y == 0 then
                    e.rigidbody.velocity.y = 0
                end

                e.rigidbody.velocity.x = e.rigidbody.velocity.x + e.rigidbody.acceleration.x * deltaTime
                e.rigidbody.velocity.y = e.rigidbody.velocity.y + vel * 0.5 * deltaTime

                --if not onGround then
                --    e.rigidbody.velocity.y = e.rigidbody.velocity.y - GRAVITY * deltaTime
                --end
            end

            if e.jelly then
                e.jelly.programTimer:tick()
                if e.jelly.programTimer:elapsed() then
                    local command = e.jelly.program:sub(e.jelly.programIndex, e.jelly.programIndex)

                    e.jelly.programIndex = 1 + e.jelly.programIndex
                    if e.jelly.programIndex > e.jelly.program:len() then
                        e.jelly.programIndex = 1
                    end
                    local nextCommand = e.jelly.program:sub(e.jelly.programIndex, e.jelly.programIndex)

                    if command == '.' then
                        -- Чилим! 🍸
                        if nextCommand ~= '.' then
                            -- Похоже скоро будем дэшить
                            e.sprite.animation = 2
                        else
                            e.sprite.animation = 1
                        end
                    elseif command == 'u' then
                        e.rigidbody.velocity.y = JELLY.DASH_STRENGTH
                        e.sprite.animation = 3
                    elseif command == 'd' then
                        e.rigidbody.velocity.y = -1 * JELLY.DASH_STRENGTH
                        e.sprite.animation = 3
                    elseif command == 'l' then
                        e.rigidbody.velocity.x = -1 * JELLY.DASH_STRENGTH
                        e.sprite.animation = 3
                    elseif command == 'r' then
                        e.rigidbody.velocity.x = JELLY.DASH_STRENGTH
                        e.sprite.animation = 3
                    end

                    e.jelly.programTimer:restart() 
                end
            end
        end

        if e.ground_physics and not Map.isWater(tile) then
            local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
            local collisionY = Physics.move_y(e.position, e.hitbox, e.rigidbody.velocity.y * deltaTime)

            e.rigidbody.velocity.y = e.rigidbody.velocity.y - GRAVITY * deltaTime
        end

        if e.rigidbody and e.player then
            e.rigidbody.velocity.x = lume.clamp(e.rigidbody.velocity.x, -PLAYER.MAX_VELOCITY, PLAYER.MAX_VELOCITY)
            e.rigidbody.velocity.y = lume.clamp(e.rigidbody.velocity.y, -PLAYER.MAX_VELOCITY, PLAYER.MAX_VELOCITY)
        end

        if e.sprite then
            local animation = e.sprite.animations[e.sprite.animation]
            animation:update(deltaTime)
        end
    end)
end


function Game:draw()
    love.graphics.clear(COLOR.GAMEBOY.BACKGROUND)
    love.graphics.setColor(COLOR.WHITE)

    local player = Game.entityPool:get(self.handles.player)
    Camera.x = player.position.x
    Camera.y = player.position.y

    local left, top = Camera.x - SCREEN.WIDTH / 2, Camera.y - SCREEN.HEIGHT / 2
    local right, bot = Camera.x + SCREEN.WIDTH / 2, Camera.y + SCREEN.HEIGHT / 2

    left  = math.floor(left / 8) - 1
    right = math.floor(right / 8) + 1
    top   = math.floor(top / 8) - 1
    bot   = math.floor(bot / 8) + 1

    for y = top, bot do
        for x = left, right do
            local tileId = Map.get(x, y)
            local quad = self.getTileQuad(tileId)
            local tx, ty = Camera:worldToView(8*x, 8*y)
            love.graphics.draw(ASSETS.tilesheet, quad, lume.round(tx), lume.round(ty))
        end
    end

    self.entityPool:foreach(function(e, ref)
        if not e.position then
            return
        end

        local x, y = Camera:worldToView(e.position.x, e.position.y)

        if e.rectangle then
            --print('oxygen: '..e.player.oxygen)
            if e.player.oxygen < PLAYER.OXYGEN / 3 then
                love.graphics.setColor(COLOR.GAMEBOY.DARK)
            else
                love.graphics.setColor(COLOR.GAMEBOY.NEUTRAL)
            end
            love.graphics.rectangle('fill', x, y, e.rectangle.width, e.rectangle.height)
        end

        if e.sprite then
            local animation = e.sprite.animations[e.sprite.animation]
            animation:draw(e.sprite.spritesheet, x, y)
        end
    end)
end


Game.getTileQuad = lume.memoize(function(tileId)
    local x, y, w, h = Map.getTileTextureRegion(tileId)
    return love.graphics.newQuad(x, y, w, h, ASSETS.tilesheet)
end)
