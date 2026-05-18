-- Делаем маленький экран как в ТИКе, рендерим в него.
-- Рендерим мы на нормальное разрешение монитора типа 1920x1080
-- и просто скейлим пиксели чтобы как можно больше экрана зарисовать.
-- Этот процесс можно посмотреть в Screen и love.draw()
SCREEN = {
    WIDTH = 240,
    HEIGHT = 136,
}


-- Цвет в формате {r, g, b, a (optional)}
-- https://love2d.org/wiki/love.graphics.setColor
COLOR = {
    WHITE = lume.color('rgb(255, 255, 255)'),
    BLACK = lume.color('rgb(0, 0, 0)'),

    -- Gameboy палитра.
    -- У меня не работает Lospec, и это единственное что я знаю.
    GAMEBOY = {
        BACKGROUND = lume.color('rgb(202, 220, 159)'), 
        DARK = lume.color('rgb(15, 56, 15)'),
        GRAY = lume.color('rgb(48, 98, 48)'),
        NEUTRAL = lume.color('rgb(139, 172, 15)'),
        LIGHT = lume.color('rgb(155, 188, 15)'),
    }
}


KEYBINDS = {
    ACTION_UP    = { keys = {'w', 'up'} },
    ACTION_DOWN  = { keys = {'s', 'down'} },
    ACTION_LEFT  = { keys = {'a', 'left'} },
    ACTION_RIGHT = { keys = {'d', 'right'} },
    JUMP         = { keys = {'w', 'up', 'space'} },
}
for k, v in pairs(KEYBINDS) do
    KEYBINDS[k].name = string.lower(k)
end


PLAYER = {
    WATER_ACCELERATION = 180,
    WATER_BOUNCE = 0.5,
    WALL_BOUNCE = 0.67, -- когда рыба на суше
    GROUND_ACCELERATION = 100,
    MAX_VELOCITY = 120,

    JUMP = {
        -- MIN_T = 0.1,
        -- MAX_T = 1.1,
        -- MIN_FORCE = 800,
        -- MAX_FORCE = 5800,
        -- F — Force 😎
        short = {T=0, F=1500},
        middle = {T=0.2, F=2000},
        high = {T=0.2, F=3000},
        BUCKET = {
            'short',
            'short',
            'short',
            'short',
            'short',
            'short',
            'short',
            'short',
            'short',
            'short',
            'middle',
            'middle',
            'middle',
            'middle',
            'high',
        }
    },
}


WORLD = {
    WIDTH = 999,
    HEIGHT = 999,
    GROUND_FRICTION = 0.8,
    WATER_FRICTION = 0.97,

    TILE = {
        SOLID = { 17, 18, 50 },
        WATER = { 32, 33, 34, 49 },
    }
}


GRAVITY = 200


COMPONENT = {
    POSITION = {
        x = 0,
        y = 0,
    },
    RIGIDBODY = {
        velocity = {x = 0, y = 0},
        acceleration = {x = 0, y = 0},
    },
    HITBOX = {
        offset_x = 0,
        offset_y = 0,
        width = 0,
        height = 0,
    },
    PLAYER = {},
}
for k, v in pairs(COMPONENT) do
    COMPONENT[k].name = string.lower(k)
end
