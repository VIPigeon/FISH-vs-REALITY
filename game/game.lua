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

function update_hitbox_by_frame(e)
    -- устанавливает хитбокс, соответствующий фрейму
    assert(e.sprite)

    local currentAnimation = e.sprite.animations[e.sprite.animation]
    local currentFrameIndex = currentAnimation.position
    local currentQuad = currentAnimation.frames[currentFrameIndex]
    -- ПРЕДПОЛОГАЕТСЯ, что размер сетки одинаковый
    -- в этом случае мы можем сделать так:
    local x, y, w, h = currentQuad:getViewport()
    local frame_x = math.floor(x / w) + 1
    local frame_y = math.floor(y / h) + 1

    if e.fish then
        -- ⚠️ СНАЧАЛА идет y, потом x. извините
        e.hitbox = box_map.to_hitbox(FISH.BOX_BY_FRAME[frame_y][frame_x])
    elseif e.jelly then
        e.hitbox = box_map.to_hitbox(JELLY.BOX_BY_FRAME[frame_y][frame_x])
    end
end

function Game:createDefaultPlayer()
    local player = {
        position = {
            x = PLAYER.SPAWN_X,
            y = PLAYER.SPAWN_Y,
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
        color = COLOR.RED,
        direction = 'right',

        fish = {}, -- флаг
        sprite = {
            animation = 'right', -- Индекс текущей анимации
            animations = {
                left = anim8.newAnimation(ASSETS.fishGrid(1, 1), 1),
                right = anim8.newAnimation(ASSETS.fishGrid(1, 2), 1),
                up = anim8.newAnimation(ASSETS.fishGrid(1, 3), 1),
                down = anim8.newAnimation(ASSETS.fishGrid(1, 4), 1),

                left2right = anim8.newAnimation(ASSETS.fishGrid('2-7', 1), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                right2left = anim8.newAnimation(ASSETS.fishGrid('2-7', 2), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                up2down = anim8.newAnimation(ASSETS.fishGrid('2-7', 3), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                down2up = anim8.newAnimation(ASSETS.fishGrid('2-7', 4), FISH.TIME_PER_FRAME, 'pauseAtEnd'),

                left2up = anim8.newAnimation(ASSETS.fishGrid('9-12', 1), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                up2left = anim8.newAnimation(ASSETS.fishGrid('13-16', 1), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                right2down = anim8.newAnimation(ASSETS.fishGrid('9-12', 2), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                down2right = anim8.newAnimation(ASSETS.fishGrid('13-16', 2), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                up2right = anim8.newAnimation(ASSETS.fishGrid('9-12', 3), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                right2up = anim8.newAnimation(ASSETS.fishGrid('13-16', 3), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                up2right = anim8.newAnimation(ASSETS.fishGrid('9-12', 3), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                right2up = anim8.newAnimation(ASSETS.fishGrid('13-16', 3), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                down2left = anim8.newAnimation(ASSETS.fishGrid('9-12', 4), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
                left2down = anim8.newAnimation(ASSETS.fishGrid('13-16', 4), FISH.TIME_PER_FRAME, 'pauseAtEnd'),
            },
            spritesheet = ASSETS.fishSpritesheet,
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
        -- hitbox = {
        --     offset_x = 2,
        --     offset_y = 2,
        --     width = 5,
        --     height = 4,
        -- },
    }

    -- for _, row in ipairs(FISH.BOX_BY_FRAME) do
    --     for _, box in ipairs(row) do
    --         print(box.x1, box.y1, box.y1, box.y2)
    --     end
    --     print()
    -- end
    update_hitbox_by_frame(player)

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
    self.handles.water = {}

    local player = Game:createDefaultPlayer()

    local water = {
        position = { x = 24, y = 72 },
        water = {
            width = 80 - 4*8,
            height = 32,
            waveTimer = Timer:new(1.0),
            shader = ASSETS.waterShader,
            surfaceShader = ASSETS.waterSurfaceShader,
            surface = {},
        },
    }
    water.water.waveTimer:stop()
    local water2 = {
        position = { x = 56+2*8, y = 80 },
        water = {
            width = 24,
            height = 24,
            waveTimer = Timer:new(1.0),
            shader = ASSETS.waterShader,
        },
    }

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
            animation = 'up_release', -- Индекс текущей анимации
            animations = {
                up_prepare = anim8.newAnimation(ASSETS.jellyGrid('1-2', 1), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                up_dash = anim8.newAnimation(ASSETS.jellyGrid('3-4', 1), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                up_release = anim8.newAnimation(ASSETS.jellyGrid('5-6', 1), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),

                right_prepare = anim8.newAnimation(ASSETS.jellyGrid('1-2', 2), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                right_dash = anim8.newAnimation(ASSETS.jellyGrid('3-4', 2), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                right_release = anim8.newAnimation(ASSETS.jellyGrid('5-6', 2), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),

                down_prepare = anim8.newAnimation(ASSETS.jellyGrid('1-2', 3), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                down_dash = anim8.newAnimation(ASSETS.jellyGrid('3-4', 3), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                down_release = anim8.newAnimation(ASSETS.jellyGrid('5-6', 3), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),

                left_prepare = anim8.newAnimation(ASSETS.jellyGrid('1-2', 4), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                left_dash = anim8.newAnimation(ASSETS.jellyGrid('3-4', 4), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
                left_release = anim8.newAnimation(ASSETS.jellyGrid('5-6', 4), JELLY.TIME_PER_FRAME, 'pauseAtEnd'),
            },
            spritesheet = ASSETS.jellySpritesheet,
        },
        jelly = {
            program = '..D..R..U....L',
            programTimer = Timer:new(JELLY.TICK_FREQUENCY),
            programIndex = 1,
        },
    }

    local jelly2 = table.deepcopy(jelly)
    jelly2.position.x = 240
    jelly2.position.y = 80
    jelly2.jelly.program = 'lr'

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

    table.insert(self.handles.water, self.entityPool:put(water))
    table.insert(self.handles.water, self.entityPool:put(water2))
    self.handles.player = self.entityPool:put(player)
end


function Game:killPlayer()
    local player, ok = self.entityPool:get(self.handles.player)
    assert(ok)

    local deathParticles = love.graphics.newParticleSystem(ASSETS.whiteSquare2x2)
    deathParticles:setParticleLifetime(0.3, 1.0)
    deathParticles:setEmissionRate(10.0)
    
    deathParticles:setLinearAcceleration(-60, -60, 60, 60) -- Random movement in all directions.
    deathParticles:setColors(1, 1, 1, 1, 1, 1, 1, 0) -- Fade to transparency.

    local playerDeadBody = {
        position = { x = player.position.x, y = player.position.y },
        rigidbody = table.deepcopy(player.rigidbody),
        hitbox = table.deepcopy(player.hitbox),
        rectangle = table.deepcopy(player.rectangle),
        playerDeadBody = {
            respawnTimer = Timer:new(2.0),
        },
        particles = {
            system = deathParticles,
        },
    }

    self.entityPool:delete(self.handles.player)
    self.handles.playerDeadBody = self.entityPool:put(playerDeadBody)
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

    local newPlayer = self:createDefaultPlayer()
    newPlayer.position.x = respawnX
    newPlayer.position.y = respawnY
    self.handles.player = self.entityPool:put(newPlayer)
    self.entityPool:delete(self.handles.playerDeadBody)
end


-- TODO: перенести в адекватное место
function reloadAnimation(e)
    e.sprite.animations[e.sprite.animation]:gotoFrame(1)
    e.sprite.animations[e.sprite.animation]:resume()
end


function Game:update()
    local deltaTime = love.timer.getDelta()

    self.entityPool:foreach(function(e, ref)
        local tile = 0
        local tileX = -1
        local tileY = -1
        if e.position and e.hitbox then
            local centerX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            local centerY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            tileX, tileY = Map.worldToTile(centerX, centerY)
            tile = Map.get(tileX, tileY)
        end

        if e.checkpoint then
            local player, ok = self.entityPool:get(self.handles.player)
            if ok then
                if player.position.x > e.position.x then
                    e.checkpoint.active = true
                    e.sprite.animation = 2
                end
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
            local direction = false
            if Input.isDown(KEYBINDS.ACTION_DOWN) then
                direction = 'down'
            end
            if Input.isDown(KEYBINDS.ACTION_UP) then
                direction = 'up'
            end
            if Input.isDown(KEYBINDS.ACTION_LEFT) then
                direction = 'left'
            end
            if Input.isDown(KEYBINDS.ACTION_RIGHT) then
                direction = 'right'
            end

            if direction then
                if direction ~= e.direction then
                    e.sprite.animation = tostring(e.direction)..'2'..tostring(direction)
                    reloadAnimation(e)
                    -- e.sprite.animations[e.sprite.animation]:gotoFrame(1)
                    -- e.sprite.animations[e.sprite.animation]:resume()
                    e.direction = direction
                end
            end
        end

        if e.player then
            if e.player.oxygen <= 0 then
                self:killPlayer()
            end

            if e.rigidbody.transition == TRANSITION.WATER_TO_LAND or e.rigidbody.transition == TRANSITION.LAND_TO_WATER then
                for _, handle in ipairs(self.handles.water) do
                    local waterEntity = self.entityPool:get(handle)
                    if waterEntity.water.surface then
                        local impactX = (e.position.x + e.hitbox.offset_x + e.hitbox.width / 2) - waterEntity.position.x

                        waterEntity.water.waveTimer:restart()
                        waterEntity.water.surfaceShader:send('center', impactX / waterEntity.water.width)
                        waterEntity.water.surfaceShader:send('strength', e.rigidbody.transition == TRANSITION.WATER_TO_LAND and -1 or 1)
                    end
                end
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
            local wereWeInWaterAtStart = Map.isWater(tile)

            if (e.player and self.debug.godmode) or Map.isWater(tile) then
                local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
                if collisionX ~= nil then
                    e.rigidbody.velocity.x = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.x
                    --if math.abs(e.rigidbody.velocity.x) < 75 then
                    --    e.rigidbody.velocity.x = -1 * e.rigidbody.velocity.x
                    --else
                    --    e.rigidbody.velocity.x = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.x
                    --end
                end

                local collisionY = Physics.move_y(e.position, e.hitbox, e.rigidbody.velocity.y * deltaTime)
                if collisionY ~= nil then
                    e.rigidbody.velocity.y = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.y
                end

                if e.rigidbody.acceleration.x == 0 then
                    e.rigidbody.velocity.x = e.rigidbody.velocity.x * math.pow(WORLD.WATER_FRICTION, deltaTime)
                    if math.abs(e.rigidbody.velocity.x) < 1 then
                        e.rigidbody.velocity.x = 0
                    end
                end

                if e.rigidbody.acceleration.y == 0 then
                    e.rigidbody.velocity.y = e.rigidbody.velocity.y * math.pow(WORLD.WATER_FRICTION, deltaTime)
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
                    e.rigidbody.velocity.x = e.rigidbody.velocity.x * math.pow(WORLD.GROUND_FRICTION, deltaTime)
                    if math.abs(e.rigidbody.velocity.x) < 1 then
                        e.rigidbody.velocity.x = 0
                    end
                end

                if onGround and e.rigidbody.acceleration.y == 0 then
                    e.rigidbody.velocity.y = 0
                end

                e.rigidbody.velocity.x = e.rigidbody.velocity.x + e.rigidbody.acceleration.x * deltaTime
                e.rigidbody.velocity.y = e.rigidbody.velocity.y + vel * 0.5 * deltaTime
            end

            local centerX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            local centerY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            local areWeInWater = Map.isWater(Map.get(Map.worldToTile(centerX, centerY)))

            if areWeInWater and not wereWeInWaterAtStart then
                e.rigidbody.transition = TRANSITION.LAND_TO_WATER
            elseif not areWeInWater and wereWeInWaterAtStart then
                e.rigidbody.transition = TRANSITION.WATER_TO_LAND
            else
                e.rigidbody.transition = TRANSITION.NIL
            end
        end

        if e.playerDeadBody then
            e.playerDeadBody.respawnTimer:tick()
            if e.playerDeadBody.respawnTimer:elapsed() then
                self:respawnPlayer()
            end
        end

        if e.jelly then
            e.jelly.programTimer:tick()
            if e.jelly.programTimer:elapsed() then
                local command = e.jelly.program:char(e.jelly.programIndex)
                local bigDash = command ~= '.' and isUpper(command)
                command = command:lower()

                local nextCommandIndex = e.jelly.programIndex
                while e.jelly.program:char(nextCommandIndex) == '.' do
                    nextCommandIndex = moduloIncrement(nextCommandIndex, e.jelly.program:len())
                end

                local nextCommand = e.jelly.program:char(nextCommandIndex)
                local nextCommandBig = isUpper(nextCommand)
                nextCommand = nextCommand:lower()

                local rotations = {
                    ['u'] = { rotation = 0,             flipH = false, flipV = false },
                    ['d'] = { rotation = ROTATE_180,    flipH = false, flipV = true },
                    ['l'] = { rotation = ROTATE_LEFT, flipH = false, flipV = false },
                    ['r'] = { rotation = ROTATE_RIGHT, flipH = false, flipV = false },
                }
                local directions = {
                    ['u'] = {  0, -1 },
                    ['d'] = {  0,  1 },
                    ['l'] = { -1,  0 },
                    ['r'] = {  1,  0 },
                }

                if command == '.' and nextCommand ~= '.' then
                    e.sprite.rotation = rotations[nextCommand].rotation
                    e.sprite.flipH = rotations[nextCommand].flipH
                    e.sprite.flipV = rotations[nextCommand].flipV
                end

                local dashStrength = 0.0
                if bigDash then
                    local distanceToWallWereFacing = 0

                    local tx = tileX
                    local ty = tileY
                    while not Map.isSolid(tx, ty) and math.abs(ty - tileY) < 10 and math.abs(tx - tileX) < 10 do
                        tx = tx + directions[command][1]
                        ty = ty + directions[command][2]
                    end

                    if nextCommand == 'u' then
                        distanceToWallWereFacing = e.position.y + e.hitbox.offset_y - (ty * 8 + 8)
                    elseif nextCommand == 'd' then
                        distanceToWallWereFacing = (ty * 8) - (e.position.y + e.hitbox.offset_y + e.hitbox.height)
                    elseif nextCommand == 'l' then
                        distanceToWallWereFacing = e.position.x + e.hitbox.offset_x - (tx * 8 + 8)
                    elseif nextCommand == 'r' then
                        distanceToWallWereFacing = (tx * 8) - (e.position.x + e.hitbox.offset_x + e.hitbox.width)
                    end

                    local frictionPerFrame = math.pow(WORLD.WATER_FRICTION, deltaTime)
                    local toWallDashStrength = distanceToWallWereFacing * (1 - frictionPerFrame) / deltaTime

                    local desiredBounceDistance = 4
                    if command == 'u' or command == 'd' then
                        desiredBounceDistance = 2*desiredBounceDistance
                    end
                    local extraForce = desiredBounceDistance * (1 - frictionPerFrame) / deltaTime

                    dashStrength = toWallDashStrength + extraForce
                else
                    dashStrength = JELLY.DASH_STRENGTH
                end

                -- Чтобы медуза меняла цвет. Геймджем, ничего не попишешь...
                local animationBonus = nextCommandBig and 3 or 0

                e.jelly.programIndex = moduloIncrement(e.jelly.programIndex, e.jelly.program:len())

                local prev_animation = e.sprite.animation
                if command == '.' then
                    -- похоже скоро будем дэшить
                    local next_tic = e.jelly.program:char(e.jelly.programIndex)
                    if next_tic == 'u' then
                        e.sprite.animation = 'up_prepare'
                    elseif next_tic == 'd' then
                        e.sprite.animation = 'down_prepare'
                    elseif next_tic == 'l' then
                        e.sprite.animation = 'left_prepare'
                    elseif next_tic == 'r' then
                        e.sprite.animation = 'right_prepare'
                    else
                        -- Чилим! 🍸
                        if nextCommand == 'u' then
                            e.sprite.animation = 'up_release'
                        elseif nextCommand == 'd' then
                            e.sprite.animation = 'down_release'
                        elseif nextCommand == 'l' then
                            e.sprite.animation = 'left_release'
                        elseif nextCommand == 'r' then
                            e.sprite.animation = 'right_release'
                        end
                    end
                elseif command == 'u' then
                    e.rigidbody.velocity.y = dashStrength
                    e.sprite.animation = 'up_dash'
                elseif command == 'd' then
                    e.rigidbody.velocity.y = -1 * dashStrength
                    e.sprite.animation = 'down_dash'
                elseif command == 'l' then
                    e.rigidbody.velocity.x = -1 * dashStrength
                    e.sprite.animation = 'left_dash'
                elseif command == 'r' then
                    e.rigidbody.velocity.x = dashStrength
                    e.sprite.animation = 'right_dash'
                end

                if e.sprite.animation ~= prev_animation then
                    reloadAnimation(e)
                end

                e.jelly.programTimer:restart() 
            end
        end

        if e.particles then
            e.particles.system:update(deltaTime)
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

    self.entityPool:foreach(function(e, ref)
        if e.player or e.jelly then
            local oldWidth = e.hitbox.offset_x
            local oldHeight = e.hitbox.offset_y
            local oldPosition = { x = e.position.x + e.hitbox.offset_x, y = e.position.y + e.hitbox.offset_y }

            update_hitbox_by_frame(e)

            local current_rect = Hitbox.to_rect(e.hitbox, e.position.x, e.position.y)
            local collision = Physics.check_collision_rect_tilemap(current_rect)
            if collision ~= nil then
                Physics.try_to_unstuck_rigidbody(oldPosition, e.hitbox)
                e.position.x = oldPosition.x - e.hitbox.offset_x
                e.position.y = oldPosition.y - e.hitbox.offset_y
            end
        end
    end)

end


function Game:draw()
    love.graphics.clear(COLOR.GAMEBOY.BACKGROUND)
    love.graphics.setColor(COLOR.WHITE)

    local player, ok = self.entityPool:get(self.handles.player)
    if not ok then
        player, ok = self.entityPool:get(self.handles.playerDeadBody)
        assert(ok)
    end
    Camera.x = player.position.x
    -- Camera.y = player.position.y
    Camera.y = PLAYER.SPAWN_Y

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
        if e.water then
            if e.water.surface then
                e.water.shader:send('y', e.position.y + 8)
                e.water.shader:send('height', e.water.height - 8)
                e.water.shader:send('colorTop', WORLD.WATER_COLOR_TOP)
                e.water.shader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
                e.water.surfaceShader:send('y', e.position.y)
                e.water.surfaceShader:send('height', 8)
                e.water.surfaceShader:send('colorTop', WORLD.WATER_COLOR_TOP)
                e.water.surfaceShader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
                if not e.water.waveTimer:elapsed() then
                    e.water.waveTimer:tick()
                    e.water.surfaceShader:send('time', e.water.waveTimer:timeElapsed())
                else
                    e.water.surfaceShader:send('strength', 0)
                end
            else
                e.water.shader:send('y', e.position.y)
                e.water.shader:send('height', e.water.height)
                e.water.shader:send('colorTop', WORLD.WATER_COLOR_TOP)
                e.water.shader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
            end

            if e.water.surface then
                assert(e.water.height >= 8)
                love.graphics.setShader(e.water.surfaceShader)
                love.graphics.draw(ASSETS.whitePixel, x, y, 0, e.water.width, 8)

                love.graphics.setShader(e.water.shader)
                love.graphics.setColor(COLOR.WHITE)
                love.graphics.draw(ASSETS.whitePixel, x, y + 8, 0, e.water.width, e.water.height - 8)
            else
                love.graphics.setShader(e.water.shader)
                love.graphics.setColor(COLOR.WHITE)
                love.graphics.draw(ASSETS.whitePixel, x, y, 0, e.water.width, e.water.height)
            end
            love.graphics.setShader()
        end
    end)

    self.entityPool:foreach(function(e, ref)
        if not e.position then
            return
        end

        local x, y = Camera:worldToView(e.position.x, e.position.y)

        if e.rectangle then
            if e.player then
                if e.player.oxygen < PLAYER.OXYGEN / 3 then
                    love.graphics.setColor(COLOR.GAMEBOY.DARK)
                else
                    love.graphics.setColor(COLOR.GAMEBOY.NEUTRAL)
                end
            end
            love.graphics.rectangle('fill', x, y, e.rectangle.width, e.rectangle.height)
        end

        if e.sprite and not e.water then
            local animation = e.sprite.animations[e.sprite.animation]
            local w, h = animation:getDimensions()

            if e.color then
                love.graphics.setColor(e.color)
            end
            animation:draw(e.sprite.spritesheet, x, y, e.sprite.rotation)
        end

        if e.particles then
            love.graphics.setColor(COLOR.GAMEBOY.LIGHT)
            love.graphics.draw(e.particles.system, x + 4, y + 4)
            love.graphics.setColor(COLOR.WHITE)
        end
    end)
end


Game.getTileQuad = lume.memoize(function(tileId)
    local x, y, w, h = Map.getTileTextureRegion(tileId)
    return love.graphics.newQuad(x, y, w, h, ASSETS.tilesheet)
end)
