Game = {}

function Game:init()
    Screen:init(SCREEN.WIDTH, SCREEN.HEIGHT)
    Input.init()
    Map.init(love.filesystem.load('content/tilemap/map.lua')())

    self.entityPool = Pool:new(Entity)
    self.refs = {}
    self.tilesheet = love.graphics.newImage('content/tilemap/tilesheet.png')

    self:restart()
end


function Game:restart()
    self.refs.player, entity = self.entityPool:grab()
    Entity.addComponent(entity, COMPONENT.PLAYER)
    local hitbox = Entity.addComponent(entity, COMPONENT.HITBOX)
    hitbox.offset_x = 0
    hitbox.offset_y = 0
    hitbox.width = 8
    hitbox.height = 8
    Entity.addComponent(entity, COMPONENT.RIGIDBODY)
    local position = Entity.addComponent(entity, COMPONENT.POSITION)
    position.x = 40
    position.y = 80

    self.getTileQuad = lume.memoize(function(tileId)
        local x, y, w, h = Map.getTileTextureRegion(tileId)
        return love.graphics.newQuad(x, y, w, h, self.tilesheet)
    end)
end


function Game:update()
    local deltaTime = love.timer.getDelta()

    self.entityPool:foreach(function(e, ref)
        local tile = 0
        if e.position then
            local centerX = e.position.x + e.hitbox.offset_x + e.hitbox.width / 2
            local centerY = e.position.y + e.hitbox.offset_y + e.hitbox.height / 2
            tile = Map.get(Map.worldToTile(centerX, centerY))
        end

        if e.player then
            if Map.isWater(tile) then
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

                if Input.isDown(KEYBINDS.ACTION_LEFT) then
                    e.rigidbody.acceleration.x = e.rigidbody.acceleration.x - PLAYER.GROUND_ACCELERATION
                end

                if Input.isDown(KEYBINDS.ACTION_RIGHT) then
                    e.rigidbody.acceleration.x = e.rigidbody.acceleration.x + PLAYER.GROUND_ACCELERATION
                end

                if Input.isJustPressed(KEYBINDS.JUMP) then
                    e.rigidbody.acceleration.y = 10000
                end
            end
        end

        if e.rigidbody then
            if Map.isWater(tile) then
                local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
                if collisionX ~= nil then
                    e.rigidbody.velocity.x = -1 * PLAYER.WATER_BOUNCE * e.rigidbody.velocity.x
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
                local collisionX = Physics.move_x(e.position, e.hitbox, e.rigidbody.velocity.x * deltaTime)
                if collisionX ~= nil then
                    e.rigidbody.velocity.x = 0
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
                e.rigidbody.velocity.y = e.rigidbody.velocity.y + e.rigidbody.acceleration.y * deltaTime

                if not onGround then
                    e.rigidbody.velocity.y = e.rigidbody.velocity.y - GRAVITY * deltaTime
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
    end)
end


function Game:draw()
    love.graphics.clear(COLOR.GAMEBOY.BACKGROUND)
    love.graphics.setColor(COLOR.WHITE)

    for y = 0, Map.terrain.height - 1 do
        for x = 0, Map.terrain.width - 1 do
            local tileId = Map.get(x, y)
            local quad = self.getTileQuad(tileId)
            love.graphics.draw(self.tilesheet, quad, 8*x, 8*y)
        end
    end

    self.entityPool:foreach(function(e, ref)
        if e.player then
            love.graphics.setColor(COLOR.GAMEBOY.NEUTRAL)
            love.graphics.rectangle('fill', e.position.x, e.position.y, 8, 8)
        end
    end)
end
