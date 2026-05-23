Game = {}

function Game:init()
    -- Находится в Data
    ASSETS:loadAll()
    --

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
            maxVelocityTime = CountingTimer:new(),
            maxVelocityGrace = Timer:new(PLAYER.SUPER_VELOCITY_GRACE_TIME),
            maxVelocity = 0.0,
            oxygen = PLAYER.OXYGEN,
            jump = {
                -- багоопасно. копирование по ссылке. ебануть не должно
                bucket = PLAYER.JUMP.BUCKET,
                i = 1,
                t = 0,

                x_i = 1,
                x_bucket = PLAYER.JUMP.X_BUCKET,
            },
            stunnedTimer = Timer:new(JELLY.STUN_TIME),
            stunClickTimer = Timer:new(0.1),
            spawnRippleTimer = Timer:new(0.2),
        },
        shake = {
            offset_x = 0,
            offset_y = 0,
            magnitude = 1,
            timer = Timer:new(PLAYER.STUN_CLICK_SHAKE_DURATION),
        },
        color = COLOR.RED,
        direction = 'right',

        fish = {}, -- флаг
        sprite = {
            animation = 'right', -- Индекс текущей анимации
            animations = {
                left = anim8.newAnimation(ASSETS.fishGrid('13-14', 5), FISH.TIME_PER_FRAME*4),
                right = anim8.newAnimation(ASSETS.fishGrid('13-14', 6), FISH.TIME_PER_FRAME*4),
                up = anim8.newAnimation(ASSETS.fishGrid('13-14', 7), FISH.TIME_PER_FRAME*4),
                down = anim8.newAnimation(ASSETS.fishGrid('13-14', 8), FISH.TIME_PER_FRAME*4),

                -- up_left = anim8.newAnimation(ASSETS.fishGrid(11, 1), 1),
                -- left_up = anim8.newAnimation(ASSETS.fishGrid(9, 1), 1),

                -- down_left = anim8.newAnimation(ASSETS.fishGrid(9, 4), 1),
                -- left_down = anim8.newAnimation(ASSETS.fishGrid(11, 4), 1),

                -- up_right = anim8.newAnimation(ASSETS.fishGrid(9, 3), 1),
                -- right_up = anim8.newAnimation(ASSETS.fishGrid(11, 3), 1),

                -- down_right = anim8.newAnimation(ASSETS.fishGrid(11, 2), 1),
                -- right_down = anim8.newAnimation(ASSETS.fishGrid(9, 2), 1),

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

                agony_left = anim8.newAnimation(ASSETS.fishGrid('1-4', 5), FISH.AGONY_TIME_PER_FRAME),
                agony_right = anim8.newAnimation(ASSETS.fishGrid('1-4', 6), FISH.AGONY_TIME_PER_FRAME),
                agony_up = anim8.newAnimation(ASSETS.fishGrid('1-4', 7), FISH.AGONY_TIME_PER_FRAME),
                agony_down = anim8.newAnimation(ASSETS.fishGrid('1-4', 8), FISH.AGONY_TIME_PER_FRAME),
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
    player.player.stunnedTimer:stop()

    -- for _, row in ipairs(FISH.BOX_BY_FRAME) do
    --     for _, box in ipairs(row) do
    --         print(box.x1, box.y1, box.y1, box.y2)
    --     end
    --     print()
    -- end
    update_hitbox_by_frame(player)

    self.music = ASSETS.music
    self.music:setLooping(true)
    self.music:setVolume(0.0)
    self.music:play()
    self.musicTimer = 0
    self.musicVolume = 0.5

    local jump_type = player.player.jump.bucket[1]
    player.player.jump.t = PLAYER.JUMP[jump_type].T
    table.shuffle(player.player.jump.bucket)

    return player
end


function Game:spawn_jelly(x, y, direction)
    local jelly = {
        position = { x = x*8, y = y*8 },
        rigidbody = {
            velocity = { x = 0, y = 0 },
            acceleration = { x = 0, y = 0 },
        },
        hitbox = {
            offset_x = 0,
            offset_y = 0,
            width = 1,
            height = 1,
        },
        color = COLOR.BRIGHTEST,
        sprite = {
            animation = tostring(direction)..'_release',
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
            program = JELLY.build_program(x, y), -- в тайлах
            programTimer = Timer:new(0.5), -- потом будем думать
            programIndex = 1,
            -- program = JELLY_PROGRAMS[program_type],
            -- programTimer = Timer:new(JELLY_programTimer[program_type]),
            -- programIndex = JELLY_programIndex[program_type][direction],
        },
    }

    update_hitbox_by_frame(jelly)
    jelly.position.x = (8*x + 4) - jelly.hitbox.offset_x - jelly.hitbox.width/2
    jelly.position.y = (8*y + 4) - jelly.hitbox.offset_y - jelly.hitbox.height/2

    return jelly
end

function Game:spawn_jelly_if_can(x, y)
    local tile = Map.get(x, y, 'spawn')
    for direction, tile_id in pairs(JELLY.markers.small_spawn) do
        if tile_id == tile then
            return self:spawn_jelly(x, y, direction)
        end
    end
    for direction, tile_id in pairs(JELLY.markers.big_spawn) do
        if tile_id == tile then
            return self:spawn_jelly(x, y, direction)
        end
    end
    return false
end


function Game:init_spawn_points()
    for x = 0, Map.spawn.width - 1 do
        for y = 0, Map.spawn.height - 1 do
            local jelly = self:spawn_jelly_if_can(x, y)
            if jelly then
                self.entityPool:put(jelly)
            end

            if Map.get(x, y, 'spawn') == MICRO_FISH_SPAWN_TILE then
                local microFish = {
                    position = { x = 8*x, y = 8*y },
                    rigidbody = {
                        velocity = { x = 0, y = 0 },
                        acceleration = { x = 0, y = 0 },
                    },
                    hitbox = {
                        offset_x = 2,
                        offset_y = 1,
                        width = 3,
                        height = 4,
                    },
                    microFish = {
                        target = { x = 8*x, y = 8*y },
                        spawn = {x = 8*x, y = 8*y },
                    },
                    color = COLOR.LIGHT_RED,
                    sprite = {
                        animation = 1,
                        animations = {
                            anim8.newAnimation(ASSETS.miniFishGrid(1, 1), 1.0),
                            anim8.newAnimation(ASSETS.miniFishGrid(2, 1), 1.0),
                        },
                        spritesheet = ASSETS.miniFish,
                    },
                }
                self.entityPool:put(microFish)
            end
        end
    end
end

function Game:restart()
    math.randomseed(os.time()*1e7)

    self.entityPool = Pool:new()
    self.handles = {} -- Тут лежат ссылки на entities, если к ним нужен доступ
                      -- Handles это прикольная тема, можно почитать тут:
                      -- https://floooh.github.io/2018/06/17/handles-vs-pointers.html
    self.handles.water = {}

    local player = Game:createDefaultPlayer()

    local mollusk = {
        position = { x = 456, y = 176 },
        sprite = {
            animation = 1,
            animations = {
                anim8.newAnimation(ASSETS.molluskGrid(1, 1), 0.5, 'pauseAtEnd'),
                anim8.newAnimation(ASSETS.molluskGrid(2, 1), 0.5, 'pauseAtEnd'),
            },
            spritesheet = ASSETS.mollusk,
        },
        hitbox = {
            offset_x = 0,
            offset_y = 0,
            width = 48,
            height = 16,
        },
    }
    mollusk.playerNearCheck = {
        distance = 30,
        inside = function()
            mollusk.sprite.animation = 2
        end,
        outside = function()
            mollusk.sprite.animation = 1
        end,
    }

    local cut = {
        position = { x = 0, y = 0 },
        cut = {},
        color = table.deepcopy(COLOR.WHITE),
        sprite = {
            spritesheet = ASSETS.cut,
            animation = 1,
            animations = {
                anim8.newAnimation(ASSETS.cutGrid('1-2', 1), 0.1),
                anim8.newAnimation(ASSETS.cutGrid('1-2', 2), 0.1),
                anim8.newAnimation(ASSETS.cutGrid('1-2', 3), 0.1),
                anim8.newAnimation(ASSETS.cutGrid('1-2', 4), 0.1),
            },
        },
    }
    self.entityPool:put(cut)

    self.entityPool:put(mollusk)

    local bubbleParticles = love.graphics.newParticleSystem(ASSETS.whiteSquare2x2)
    bubbleParticles:setParticleLifetime(5.0, 16.0)
    bubbleParticles:setEmissionRate(10.0)
    bubbleParticles:setEmissionArea('uniform', 400, 100)
    bubbleParticles:setTexture(ASSETS.bubble4x4)
    bubbleParticles:setLinearAcceleration(-2, -1, 2, -2.5)
    bubbleParticles:setColors(1, 1, 1, 0.5, 1, 1, 1, 0)
    local bubbles = {
        position = { x = 500, y = 360 },
        particles = {
            system = bubbleParticles,
            layer = -1,
        },
    }

    local bigBubbleSystem = bubbleParticles:clone()
    bigBubbleSystem:setTexture(ASSETS.bubble6x6)
    bigBubbleSystem:setEmissionRate(3.0)
    local bigBubbles = {
        position = {},
        particles = {
            system = bigBubbleSystem,
            layer = -1,
        },
    }
    bigBubbles.position.x = bubbles.position.x
    bigBubbles.position.y = bubbles.position.y

    local smallBubbles = bubbleParticles:clone()
    smallBubbles:setEmissionArea('uniform', 2, 2)
    smallBubbles:setEmissionRate(5.0)
    smallBubbles:setParticleLifetime(2.0, 9.0)
    smallBubbles:setLinearAcceleration(-5, -2, 5, -12)
    smallBubbles:setTexture(ASSETS.bubble3x3)
    local pipeBubbles = {
        position = { x = 180, y = 443 },
        particles = {
            system = smallBubbles,
            layer = 0,
        },
    }
    local pipeBubbles2 = {
        position = { x = 450, y = 173 },
        particles = {
            system = smallBubbles,
            layer = 0,
        },
    }
    local pipeBubbles3 = {
        position = { x = 890, y = 200 },
        particles = {
            system = smallBubbles,
            layer = 0,
        },
    }

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
            position = { x = 6*8, y = 25*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 50*8, y = 32*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x =110*8, y = 25*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 170*8, y = 25*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 206*8, y = 25*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        {
            position = { x = 253*8, y = 32*8, },
            checkpoint = {
                active = false,
            },
            sprite = table.copy(checkpointSprite),
        },
        -- {
        --     position = { x = 96, y = 56, },
        --     checkpoint = {
        --         active = false,
        --     },
        --     sprite = table.copy(checkpointSprite),
        -- },
        -- {
        --     position = { x = 176, y = 40, },
        --     checkpoint = {
        --         active = false,
        --     },
        --     sprite = table.copy(checkpointSprite),
        -- },
        -- {
        --     position = { x = 248, y = 40, },
        --     checkpoint = {
        --         active = false,
        --     },
        --     sprite = table.copy(checkpointSprite),
        -- },
    }


    for _, checkpoint in ipairs(checkpoints) do
        self.entityPool:put(checkpoint)
    end
    self.entityPool:put(jelly)
    self.entityPool:put(jelly2)
    self.entityPool:put(bubbles)
    self.entityPool:put(pipeBubbles)
    self.entityPool:put(pipeBubbles2)
    self.entityPool:put(pipeBubbles3)
    self.entityPool:put(bigBubbles)

    self.handles.player = self.entityPool:put(player)

    used = {}
    for x = 0, Map.terrain.width - 1 do
        for y = 0, Map.terrain.height - 1 do
            if not table.contains(used, y*Map.terrain.width+x) then
                local tile = Map.get(x, y)
                local isWater = table.contains(WORLD.TILE.WATER, tile)
                local isSurface = table.contains(WORLD.TILE.TOP_WATER, tile)
                if isWater and not isSurface then
                    for ty = y, Map.terrain.height - 1 do
                        table.insert(used, ty*Map.terrain.width+x)
                    end
                    table.insert(used, y*Map.terrain.width + x)
                    local water = {
                        position = { x = 8*x, y = 8*y },
                        water = {
                            width = 8,
                            height = WORLD.WATER_MAX_HEIGHT - 8*y,
                        },
                    }
                    self.entityPool:put(water)
                end
            end
        end
    end

    used = {}
    for y = 0, Map.terrain.height - 1 do
        for x = 0, Map.terrain.width - 1 do
            if not table.contains(used, y*Map.terrain.width+x) then
                local tile = Map.get(x, y)
                local isSurface = table.contains(WORLD.TILE.TOP_WATER, tile)
                if isSurface then
                    local tx = x
                    while table.contains(WORLD.TILE.TOP_WATER, Map.get(tx, y)) do
                        table.insert(used, y*Map.terrain.width + tx)
                        tx = tx + 1
                    end
                    table.insert(used, y*Map.terrain.width + tx)

                    local water = {
                        position = { x = 8*x, y = 8*y - 8 },
                        water = {
                            width = 8*(tx - x),
                            height = 16,
                            waveTimer = Timer:new(0.75),
                            surfaceShader = love.graphics.newShader(SHADERS_SOURCES.waterSurface),
                            surface = {},
                        },
                    }
                    water.water.waveTimer:stop()

                    table.insert(self.handles.water, self.entityPool:put(water))
                end
            end
        end
    end

    self:init_spawn_points()
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
            layer = 1,
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
        local centerX = -1
        local centerY = -1
        if e.position and e.hitbox then
            centerX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            centerY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            tileX, tileY = Map.worldToTile(centerX, centerY)
            tile = Map.get(tileX, tileY)
        end

        if e.cut then
            local player, ok = self.entityPool:get(self.handles.player)
            if ok and player.player.maxVelocity > PLAYER.MAX_VELOCITY then
                local playerX = player.position.x + player.hitbox.offset_x + player.hitbox.width / 2
                local playerY = player.position.y + player.hitbox.offset_y + player.hitbox.height / 2
                tileX, tileY = Map.worldToTile(playerX, playerY)
                if Map.isWater(Map.get(tileX, tileY), playerY) then
                    e.color[4] = math.max(0, 0.1 * (vectorLength(player.rigidbody.velocity.x, player.rigidbody.velocity.y) - 60) / PLAYER.MAX_VELOCITY)
                    e.position.x = player.position.x
                    e.position.y = player.position.y
                    if math.abs(player.rigidbody.velocity.x) > math.abs(player.rigidbody.velocity.y) then
                        if player.rigidbody.velocity.x > 0 then
                            e.sprite.animation = 1
                        else
                            e.sprite.animation = 3
                        end
                    else
                        if player.rigidbody.velocity.y > 0 then
                            e.sprite.animation = 2
                        else
                            e.sprite.animation = 4
                        end
                    end
                else
                    e.color[4] = 0
                end
            end
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

        if e.microFish then
            if lume.distance(e.position.x, e.position.y, e.microFish.target.x, e.microFish.target.y) < 3 then
                e.microFish.target.x = e.microFish.spawn.x + math.random(-8, 8)
                e.microFish.target.y = e.microFish.spawn.y + math.random(-2, 2)
            end

            local direction = normalize(e.microFish.target.x - e.position.x, e.position.y - e.microFish.target.y)
            if direction.x < 0 then
                e.sprite.animation = 2
            else
                e.sprite.animation = 1
            end
            e.rigidbody.acceleration.x = 5*direction.x
            e.rigidbody.acceleration.y = 5*direction.y
        end

        if e.player then
            if Map.isWater(tile, centerY) then
                self.musicTimer = math.min(2.0, self.musicTimer + deltaTime)
                e.player.oxygen = math.min(PLAYER.OXYGEN, e.player.oxygen + deltaTime*PLAYER.OXYGEN_INCOME)
            else
                self.musicTimer = math.max(0.0, self.musicTimer - deltaTime)
                e.player.oxygen = Time.tick(e.player.oxygen)
            end
            self.music:setVolume(self.musicVolume * self.musicTimer / 2.0)

            if self.debug.godmode then
                e.player.oxygen = PLAYER.OXYGEN
            end
        end

        if e.player then
            local direction = false
            local direction2 = false
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
            if Input.isDown(KEYBINDS.ACTION_DOWN) and Input.isDown(KEYBINDS.ACTION_LEFT) then
                direction = 'down'
                direction2 = 'left'
            end
            if Input.isDown(KEYBINDS.ACTION_UP) and Input.isDown(KEYBINDS.ACTION_LEFT) then
                direction = 'up'
                direction2 = 'left'
            end
            if Input.isDown(KEYBINDS.ACTION_RIGHT) and Input.isDown(KEYBINDS.ACTION_DOWN) then
                direction = 'down'
                direction2 = 'right'
            end
            if Input.isDown(KEYBINDS.ACTION_RIGHT) and Input.isDown(KEYBINDS.ACTION_UP) then
                direction = 'up'
                direction2 = 'right'
            end

            if direction2 then -- нажали сразу две стрелочки
                -- if e.direction == direction then
                --     e.sprite.animation = direction..'_'..direction2
                -- elseif e.direction == direction2 then
                --     e.sprite.animation = direction2..'_'..direction
                -- elseif e.direction == 'up' or e.direction == 'down' then
                --     e.sprite.animation = direction2..'_'..direction
                -- else -- if e.direction == 'left' or e.direction == 'right' then
                --     e.sprite.animation = direction..'_'..direction2
                -- end
            elseif direction then
                if direction ~= e.direction then
                    e.sprite.animation = e.direction..'2'..direction
                    reloadAnimation(e)
                    -- e.sprite.animations[e.sprite.animation]:gotoFrame(1)
                    -- e.sprite.animations[e.sprite.animation]:resume()
                    e.direction = direction
                elseif e.sprite.animations[e.sprite.animation].status == 'paused' then
                    reloadAnimation(e)
                    e.sprite.animation = direction
                end
            else
                if e.sprite.animation == 'left' or
                        e.sprite.animation == 'right' or
                        e.sprite.animation == 'up' or
                        e.sprite.animation == 'down' then
                    reloadAnimation(e)
                    e.sprite.animations[e.sprite.animation]:pause()
                end
            end

            if not Map.isWater(tile, centerY) then
                local a = e.sprite.animation
                if not string.find(a, '2') and not string.find(a, 'agony') then
                    e.sprite.animation = 'agony_'..(e.direction)
                end
            elseif string.find(e.sprite.animation, 'agony') then
                e.sprite.animation = e.direction
            end

            if not e.player.stunnedTimer:elapsed() then
                e.sprite.animation = 'agony_right'
            end
        end

        if e.playerNearCheck then
            local player = self.entityPool:get(self.handles.player)
            if player then
                if lume.distance(player.position.x, player.position.y, centerX, centerY) < e.playerNearCheck.distance then
                    e.playerNearCheck.inside()
                else
                    e.playerNearCheck.outside()
                end
            end
        end

        -- Прошу внимание, хайку:
        if e.death then
            e.death:tick()
            if e.death:elapsed() then
                self.entityPool:delete(ref)
            end
        end

        if e.player then
            if Map.isWater(tile, e.position.y) then
                e.rigidbody.velocity.x = lume.clamp(e.rigidbody.velocity.x, -e.player.maxVelocity, e.player.maxVelocity)
                e.rigidbody.velocity.y = lume.clamp(e.rigidbody.velocity.y, -e.player.maxVelocity, e.player.maxVelocity)
            end

            local vl = vectorLength(e.rigidbody.velocity.x, e.rigidbody.velocity.y)
            if vl >= 0.7*PLAYER.MAX_VELOCITY then
                e.player.maxVelocityTime:tick(deltaTime)
                e.player.maxVelocityGrace:restart()
            else
                e.player.maxVelocityGrace:tick()
                if e.player.maxVelocityGrace:elapsed() then
                    e.player.maxVelocityTime:reset()
                end
            end

            if e.player.maxVelocityTime.duration > PLAYER.TIME_AT_MAX_SPEED_TO_REACH_TOP_SPEED then
                e.player.maxVelocity = PLAYER.MAX_SUPER_VELOCITY
            else
                e.player.maxVelocity = PLAYER.MAX_VELOCITY
            end

            e.player.spawnRippleTimer:tick()
            if Map.isWater(tile, 0) and e.player.spawnRippleTimer:elapsed() and vectorLength(e.rigidbody.velocity.x, e.rigidbody.velocity.y) > 80 then
                e.player.spawnRippleTimer:restart()
                local ripple = {
                    position = { x = e.position.x, y = e.position.y },
                    sprite = {
                        spritesheet = ASSETS.ripple,
                        animation = 1,
                        animations = {
                            anim8.newAnimation(ASSETS.rippleGrid('1-4', 1), 0.1),
                        },
                    },
                    death = Timer:new(0.5),
                }

                self.entityPool:put(ripple)
            end


            local onGround = Physics.is_on_ground(e.position, e.hitbox)
            if onGround and e.player.oxygen <= 0 then
                self:killPlayer()
            end

            if not e.player.stunnedTimer:elapsed() then
                e.color = COLOR.PURPLE
            elseif e.player.oxygen < PLAYER.OXYGEN / 4 then
                e.color = COLOR.BLUE
            elseif e.player.oxygen < PLAYER.OXYGEN / 2 then
                e.color = COLOR.LIGHT_BLUE
            else
                e.color = COLOR.RED
            end

            if e.rigidbody.transition == TRANSITION.WATER_TO_LAND or e.rigidbody.transition == TRANSITION.LAND_TO_WATER then
                for _, handle in ipairs(self.handles.water) do
                    local waterEntity = self.entityPool:get(handle)
                    if waterEntity.water.surface then
                        local impactX = (e.position.x + e.hitbox.offset_x + e.hitbox.width / 2) - waterEntity.position.x

                        waterEntity.water.waveTimer:restart()
                        waterEntity.water.surfaceShader:send('center', impactX / waterEntity.water.width)
                        local strength = 0.5
                        if vectorLength(e.rigidbody.velocity.x, e.rigidbody.velocity.y) > 90 then
                            strength = 0.8
                        end

                        waterEntity.water.surfaceShader:send('strength', e.rigidbody.transition == TRANSITION.WATER_TO_LAND and -strength or strength)
                    end
                end
            end

            e.player.stunnedTimer:tick()
            e.rigidbody.acceleration.x = 0
            e.rigidbody.acceleration.y = 0
            e.shake.offset_x = 0
            e.shake.offset_y = 0

            if e.player.stunnedTimer:elapsed() then
                if self.debug.godmode or Map.isWater(tile, centerY) then
                    if Input.isDown(KEYBINDS.ACTION_UP) then
                        e.rigidbody.acceleration.y = e.rigidbody.acceleration.y + PLAYER.WATER_ACCELERATION
                    end
                    if Input.isDown(KEYBINDS.ACTION_DOWN) then
                        e.rigidbody.acceleration.y = e.rigidbody.acceleration.y - PLAYER.WATER_ACCELERATION
                    end

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
                    local onGround = Physics.is_on_ground(e.position, e.hitbox)
                    if onGround then -- автопрыжок только на земле
                        e.player.jump.t = Time.tick(e.player.jump.t)
                        if e.player.jump.t == 0 then
                            -- прыжок
                            -- Y
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

                            -- дрифт по горизонатли во время прыжка
                            -- X
                            local drift = e.player.jump.x_bucket[e.player.jump.x_i]
                            local is_small_drift = string.find(drift, 'small')
                            local is_back_drift = string.find(drift, 'back')
                            if drift == 'none' then
                                table.shuffle(e.player.jump.x_bucket)
                                e.player.jump.x_i = 1
                            else
                                local Fx = PLAYER.JUMP.X_DRIFT['big']
                                if is_small_drift then
                                    Fx = PLAYER.JUMP.X_DRIFT['small']
                                end
                                if is_back_drift then
                                    Fx = -Fx
                                end
                                e.player.jump.x_i = e.player.jump.x_i + 1
                                e.rigidbody.velocity.x = e.rigidbody.velocity.x + Fx
                            end
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
            else
                e.shake.timer:tick()
                e.player.stunClickTimer:tick()

                local actionPressed = false
                if Input.isJustPressed(KEYBINDS.ACTION_UP) then
                    actionPressed = true
                elseif Input.isJustPressed(KEYBINDS.ACTION_DOWN) then
                    actionPressed = true
                elseif Input.isJustPressed(KEYBINDS.ACTION_LEFT) then
                    actionPressed = true
                elseif Input.isJustPressed(KEYBINDS.ACTION_RIGHT) then
                    actionPressed = true
                end

                if actionPressed then
                    local ripple = {
                        position = { x = e.position.x, y = e.position.y },
                        sprite = {
                            spritesheet = ASSETS.ripple,
                            animation = 1,
                            animations = {
                                anim8.newAnimation(ASSETS.rippleGrid('1-4', 1), 0.05),
                            },
                        },
                        death = Timer:new(0.2),
                    }
                    ripple.position.x = ripple.position.x + math.random(-3, 3)
                    ripple.position.y = ripple.position.y + math.random(-3, 3)
                    self.entityPool:put(ripple)
                end

                if e.player.stunClickTimer:elapsed() and actionPressed then
                    e.shake.timer:restart()
                    e.player.stunClickTimer:restart()
                    e.player.stunnedTimer.currentTime = e.player.stunnedTimer.currentTime - 0.5
                end

                if not e.shake.timer:elapsed() then
                    e.shake.offset_x = math.random(-e.shake.magnitude, e.shake.magnitude)
                    e.shake.offset_y = math.random(-e.shake.magnitude, e.shake.magnitude)
                end
            end
        end

        if e.rigidbody then
            local wereWeInWaterAtStart = Map.isWater(tile, centerY)

            if e.player and self.debug.godmode then
                e.position.x = e.position.x + e.rigidbody.velocity.x * deltaTime
                e.position.y = e.position.y - e.rigidbody.velocity.y * deltaTime

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
            elseif Map.isWater(tile, centerY) then
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
                    -- if math.abs(e.rigidbody.velocity.x) < 75 then
                    --     local v = e.rigidbody.velocity.x
                    --     local V = PLAYER.MIN_V_FOR_BOUNCE
                    --     if e.rigidbody.velocity.x > 0 then
                    --         v = math.max(v, V)
                    --     else
                    --         v = math.min(v, -V)
                    --     end
                    --     e.rigidbody.velocity.x = -1 * v
                    -- else
                        e.rigidbody.velocity.x = -1 * PLAYER.WALL_BOUNCE * e.rigidbody.velocity.x
                    -- end
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

            local nextCenterX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            local nextCenterY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            local areWeInWater = Map.isWater(Map.get(Map.worldToTile(nextCenterX, nextCenterY)), nextCenterY)

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
            local player = self.entityPool:get(self.handles.player)
            if player then
                local playerRect = Hitbox.to_rect(player.hitbox, player.position.x, player.position.y)
                local ourRect = Hitbox.to_rect(e.hitbox, e.position.x, e.position.y)
                if not self.debug.godmode and player.player.stunnedTimer:elapsed() and Physics.check_collision_rect_rect(playerRect, ourRect) then
                    player.player.stunnedTimer:restart()
                    player.shake.timer:restart()
                    local direction = normalize(player.position.x - e.position.x, e.position.y - player.position.y)
                    player.rigidbody.velocity.x = direction.x * JELLY.KNOCKBACK
                    player.rigidbody.velocity.y = direction.y * JELLY.KNOCKBACK
                end
            end

            e.jelly.programTimer:tick()
            if e.jelly.programTimer:elapsed() then
                local command = e.jelly.program:char(e.jelly.programIndex)
                local bigDash = command ~= '.' and isUpper(command)
                command = command:lower()

                local nextCommandIndex = e.jelly.programIndex
                moduloIncrement(nextCommandIndex, e.jelly.program:len())
                while e.jelly.program:char(nextCommandIndex) == '.' do
                    nextCommandIndex = moduloIncrement(nextCommandIndex, e.jelly.program:len())
                end

                local nextCommand = e.jelly.program:char(nextCommandIndex)
                local nextCommandBig = nextCommand ~= '.' and isUpper(nextCommand)
                if nextCommandBig then
                    e.color = COLOR.LIGHT_RED
                else
                    e.color = COLOR.BRIGHTEST
                end
                nextCommand = nextCommand:lower()

                local directions = {
                    ['u'] = {  0, -1 },
                    ['d'] = {  0,  1 },
                    ['l'] = { -1,  0 },
                    ['r'] = {  1,  0 },
                }

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

                if nextCommandBig then
                    e.color = COLOR.LIGHT_RED
                else
                    -- e.color = COLOR.LIGHT
                    e.color = COLOR.BRIGHTEST
                end

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

        if e.sprite then
            local animation = e.sprite.animations[e.sprite.animation]
            animation:update(deltaTime)
        end
    end)

    self.entityPool:foreach(function(e, ref)
        if (not self.debug.godmode and e.player) or e.jelly then

            update_hitbox_by_frame(e)

            iteration = 0
            while iteration < 10 do
                local current_rect = Hitbox.to_rect(e.hitbox, e.position.x, e.position.y)
                local collision = Physics.check_collision_rect_tilemap(current_rect)

                if collision ~= nil then
                    local left = e.position.x + e.hitbox.offset_x
                    local right = left + e.hitbox.width
                    local top = e.position.y + e.hitbox.offset_y
                    local bottom = top + e.hitbox.height
                    if right > collision.x and left < collision.x then
                        e.position.x = collision.x - e.hitbox.width - e.hitbox.offset_x
                    elseif right > collision.x + 8 and left < collision.x + 8 then
                        e.position.x = collision.x + 8 - e.hitbox.offset_x
                    elseif bottom > e.position.y and top < collision.y then
                        e.position.y = collision.y - e.hitbox.height - e.hitbox.offset_y
                    elseif bottom > collision.y + 8 and top < collision.y + 8 then
                        e.position.y = collision.y + 8 - e.hitbox.offset_y
                    end
                else
                    break
                end

                iteration = iteration + 1
            end
        end
    end)

    local player = self.entityPool:get(self.handles.player)
    if player then
        Camera:update(player.position, deltaTime)
    end
end


function Game:draw()
    Camera:beginDraw()

    local player, ok = self.entityPool:get(self.handles.player)
    if not ok then
        player, ok = self.entityPool:get(self.handles.playerDeadBody)
        assert(ok)
    end

    self.entityPool:foreach(function(e, ref)
        local x, y = e.position.x, e.position.y
        if e.water and not e.water.surface then
            ASSETS.waterShader:send('y', e.position.y)
            ASSETS.waterShader:send('height', e.water.height)
            ASSETS.waterShader:send('colorTop', WORLD.WATER_COLOR_TOP)
            ASSETS.waterShader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
            love.graphics.setShader(ASSETS.waterShader)
            love.graphics.setColor(COLOR.WHITE)
            love.graphics.draw(ASSETS.whitePixel, x, y, 0, e.water.width, e.water.height)
            love.graphics.setShader()
        end
    end)

    self.entityPool:foreach(function(e, ref)
        local x, y = e.position.x, e.position.y
        if e.particles and e.particles.layer < 0 then
            love.graphics.draw(e.particles.system, x, y)
        end
    end)

    self.entityPool:foreach(function(e, ref)
        if not e.position then
            return
        end

        local x, y = e.position.x, e.position.y

        if e.water and e.water.surface then
            ASSETS.waterShader:send('y', e.position.y)
            ASSETS.waterShader:send('height', e.water.height)
            ASSETS.waterShader:send('colorTop', WORLD.WATER_COLOR_TOP)
            ASSETS.waterShader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
            e.water.surfaceShader:send('y', e.position.y+8)
            e.water.surfaceShader:send('height', 8)
            e.water.surfaceShader:send('colorTop', WORLD.WATER_COLOR_TOP)
            e.water.surfaceShader:send('colorBottom', WORLD.WATER_COLOR_BOTTOM)
            if not e.water.waveTimer:elapsed() then
                e.water.waveTimer:tick()
                e.water.surfaceShader:send('time', e.water.waveTimer:timeElapsed())
            else
                e.water.surfaceShader:send('strength', 0)
            end

            assert(e.water.height >= 8)
            love.graphics.setShader(e.water.surfaceShader)
            love.graphics.draw(ASSETS.whitePixel, x, y, 0, e.water.width, e.water.height)
            love.graphics.setShader()
        end
    end)

    local left, top = Camera.x, Camera.y
    local right, bot = Camera.x + SCREEN.WIDTH, Camera.y + SCREEN.HEIGHT

    left  = math.floor(left / 8) - 1
    right = math.floor(right / 8) + 1
    top   = math.floor(top / 8) - 1
    bot   = math.floor(bot / 8) + 1

    for y = top, bot do
        for x = left, right do
            local tileId = Map.get(x, y)
            local quad = self.getTileQuad(tileId)
            local tx, ty = 8*x, 8*y
            if not Map.isWater(tileId, 0) and not table.contains(WORLD.TILE.TOP_WATER, tileId) then
                love.graphics.draw(ASSETS.tilesheet, quad, lume.round(tx), lume.round(ty))
            end
            local deco = Map.get(x, y, 'decorations')
            love.graphics.draw(ASSETS.tilesheet, self.getTileQuad(deco), lume.round(tx), lume.round(ty))
        end
    end

    self.entityPool:foreach(function(e, ref)
        if not e.position then
            return
        end

        local x, y = e.position.x, e.position.y

        if e.color then
            love.graphics.setColor(e.color)
        end

        if e.rectangle then
            love.graphics.rectangle('fill', x, y, e.rectangle.width, e.rectangle.height)
        end

        if e.sprite and not e.water then
            local animation = e.sprite.animations[e.sprite.animation]
            local w, h = animation:getDimensions()

            if e.shake then
                animation:draw(e.sprite.spritesheet, x + e.shake.offset_x, y + e.shake.offset_y)
            else
                animation:draw(e.sprite.spritesheet, x, y)
            end
        end

        if e.particles and e.particles.layer >= 0 then
            love.graphics.draw(e.particles.system, x + 4, y + 4)
            love.graphics.setColor(COLOR.WHITE)
        end

        love.graphics.setColor(COLOR.WHITE)
    end)

    Camera:endDraw()
end


Game.getTileQuad = lume.memoize(function(tileId)
    local x, y, w, h = Map.getTileTextureRegion(tileId)
    return love.graphics.newQuad(x, y, w, h, ASSETS.tilesheet)
end)
