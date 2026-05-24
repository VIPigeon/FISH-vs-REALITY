-- Делаем маленький экран как в ТИКе, рендерим в него.
-- Рендерим мы на нормальное разрешение монитора типа 1920x1080
-- и просто скейлим пиксели чтобы как можно больше экрана зарисовать.
-- Этот процесс можно посмотреть в Screen и love.draw()
SCREEN = {
    WIDTH = 240,
    HEIGHT = 136,
}

CAMERA = {
    DEAD_ZONE_X = 16,
    DEAD_ZONE_Y = 9,
    SMOOTHING = 0.1,
}


-- Цвет в формате {r, g, b, a (optional)}
-- https://love2d.org/wiki/love.graphics.setColor
-- COLOR = {
--     WHITE = lume.color('rgb(255, 255, 255)'),
--     BLACK = lume.color('rgb(0, 0, 0)'),

--     PURPLE = lume.color('#46425e'),
--     BLUE = lume.color('#15788c'),
--     LIGHT_BLUE = lume.color('#00b9be'),
--     RED = lume.color('#ff6973'),
--     LIGHT_RED = lume.color('#ffb0a3'),
--     BRIGHTEST = lume.color('#ffeecc'),
--     BACKGROUND = lume.color('#413e52'),

--     -- Gameboy палитра.
--     -- У меня не работает Lospec, и это единственное что я знаю.
--     GAMEBOY = {
--         BACKGROUND = lume.color('rgb(202, 220, 159)'), 
--         DARK = lume.color('rgb(15, 56, 15)'),
--         GRAY = lume.color('rgb(48, 98, 48)'),
--         NEUTRAL = lume.color('rgb(139, 172, 15)'),
--         LIGHT = lume.color('rgb(155, 188, 15)'),
--     }
-- }
COLOR = {
    WHITE = lume.color('rgb(255, 255, 255)'),
    BLACK = lume.color('rgb(0, 0, 0)'),

    -- палитра
    RED = lume.color('#f98284'),
    LIGHT_RED = lume.color('#feaae4'), -- pink
    BLUE = lume.color('#accce4'),
    LIGHT_BLUE = lume.color('#b3e3da'),
    DARKEST = lume.color('#28282e'),
    BRIGHTEST = lume.color('#fff7e4'),

    WINE = lume.color('#6c5671'),
    PURPLE = lume.color('#b0a9e4'),
    GREY = lume.color('#d9c8bf'),
    --
}
COLOR.BACKGROUND = COLOR.WINE


KEYBINDS = {
    ACTION_UP    = { keys = {'w', 'up'} },
    ACTION_DOWN  = { keys = {'s', 'down'} },
    ACTION_LEFT  = { keys = {'a', 'left'} },
    ACTION_RIGHT = { keys = {'d', 'right'} },
    JUMP         = { keys = {'w', 'up', 'space'} },

    COUNT_DEATH = {keys={'f'}},
}
for k, v in pairs(KEYBINDS) do
    KEYBINDS[k].name = string.lower(k)
end

TRANSITION = {
    NIL = 0,
    LAND_TO_WATER = 1,
    WATER_TO_LAND = 2,
}


ROTATE_RIGHT =      0.5 * math.pi
ROTATE_LEFT  = -1 * 0.5 * math.pi
ROTATE_180 =              math.pi


PLAYER = {
    TIME_AT_MAX_SPEED_TO_REACH_TOP_SPEED = 1.4,
    SUPER_VELOCITY_GRACE_TIME = 0.5,
    STUN_CLICK_SHAKE_DURATION = 0.1,
    CLICKS_TILL_UNSTUN = 15,
    WATER_ACCELERATION = 210,
    WATER_BOUNCE = 0.5,
    WALL_BOUNCE = 0.67, -- когда рыба на суше
    GROUND_ACCELERATION = 36,
    MAX_VELOCITY = 111,
    MAX_SUPER_VELOCITY = 140,

    -- SPAWN_X = 300*8,  -- конец
    -- SPAWN_Y = 50*8,
    MAX_DEATHS = 15,  -- количество смертей, после которого мы будем максимально помогать игроку

    SPAWN_X = 17*8,
    SPAWN_Y = 9*8,

    MIN_V_FOR_BOUNCE = 30,
    JUMP = {
        -- MIN_T = 0.1,
        -- MAX_T = 1.1,
        -- MIN_FORCE = 800,
        -- MAX_FORCE = 5800,
        -- F — Force 😎
        short = {T=0, F=1550 * 1.8 * 0.016},
        -- middle = {T=0.15, F=2400 * 1.8 * 0.016},
        high = {T=0.2, F=4777 * 1.2 * 0.016},

        -- BUCKET = {
        --     'short',
        --     'short',
        --     'short',
        --     'short',
        --     'short',
        --     'short',
        --     'short',
        --     'middle',
        --     'middle',
        --     'middle',
        --     'middle',
        --     'middle',
        --     'high',
        --     'high',
        --     'high',
        -- },

        X_DRIFT = {
            ['small'] = 111*1.8*0.016,
            ['big'] = 222*1.8*0.016, -- в бане
        },
        X_BUCKET = {
            'small-back',
            'small-front',
            'none', -- перезагружаем по none
        },
    },
    OXYGEN = 11, -- время жизни без воды (секунды)
    OXYGEN_INCOME = 9, -- скорость восстановления кислорода в воде (в секунду)
}

FISH = {
    TIME_PER_FRAME = 0.04,
    BOX_BY_FRAME = box_map.get_boxes_from_image('content/fish_hitboxes.png'),

    AGONY_TIME_PER_FRAME = 0.081,
}

-- компонент для анимации рыбы
--[[
rotate:
    3
    ^
 2 < > 0
    v
    1

tail:
  -1
 0 <(((*>
  +1

Аналогично с head:
    -1
<(((*> 0
    +1

is_lying — лежит ли рыба
is_nose_flattened — сплющен ли нос
]]

-- JELLY_PROGRAMS = {
--     common = '..d..l..u..r',
--     -- common = '............',
-- }
-- JELLY_programIndex = {
--     common = {
--         down = 3,
--         left = 6,
--         up = 9,
--         right = 12,
--     },
-- }
-- JELLY_programTimer = {
--     common = 0.5, -- временно
-- }

JELLY = {
    -- DASH_STRENGTH = 60,
    DASH_STRENGTH = 119,
    BIG_DASH_STRENGTH = 120,
    -- TICK_FREQUENCY = 0.5, -- Раз в 0.5 секунд переходим на следующую команду в программе
    TICK_FREQUENCY = 0.375,
    DASH_COOLDOWN = 3,

    STUN_TIME = 5,
    KNOCKBACK = 400,

    TIME_PER_FRAME = 0.06,
    BOX_BY_FRAME = box_map.get_boxes_from_image('content/jelly-hitboxes.png'),

    markers = {
        small_spawn = {  -- первый дэш маленький
            down=177,
            up=177-16, left=177-1, right=177+1,
        },
        big_spawn = {  -- первый дэш сильный
            down=209,
            up=209-16, left=209-1, right=209+1,
        },
        -- медуза не спавнится, но дэш надо сделать!
        small_dash = {
            down=180,
            up=180-16, left=180-1, right=180+1,
        },
        big_dash = {
            down=212,
            up=212-16, left=212-1, right=212+1,
        },
    }
}

function JELLY._is_dash_mark(x, y)
    local tile = Map.get(x, y, 'spawn')
    if tile == JELLY.markers.small_spawn.down or tile == JELLY.markers.small_dash.down then
        return true
    elseif tile == JELLY.markers.small_spawn.up or tile == JELLY.markers.small_dash.up then
        return true
    elseif tile == JELLY.markers.small_spawn.left or tile == JELLY.markers.small_dash.left then
        return true
    elseif tile == JELLY.markers.small_spawn.right or tile == JELLY.markers.small_dash.right then
        return true
    elseif tile == JELLY.markers.big_spawn.down or tile == JELLY.markers.big_dash.down then
        return true
    elseif tile == JELLY.markers.big_spawn.up or tile == JELLY.markers.big_dash.up then
        return true
    elseif tile == JELLY.markers.big_spawn.left or tile == JELLY.markers.big_dash.left then
        return true
    elseif tile == JELLY.markers.big_spawn.right or tile == JELLY.markers.big_dash.right then
        return true
    end
    return false
end

function JELLY._get_dash(x, y)
    -- TODO: обрабатывать большие прыжки (надо настроить отскок после большого дэша, чтобы было ровно в тайлы)
    local tile = Map.get(x, y, 'spawn')
    local STEP = 3
    if tile == JELLY.markers.small_spawn.down or tile == JELLY.markers.small_dash.down then
        return 'd..', x, y+STEP
    elseif tile == JELLY.markers.small_spawn.up or tile == JELLY.markers.small_dash.up then
        return 'u..', x, y-STEP
    elseif tile == JELLY.markers.small_spawn.left or tile == JELLY.markers.small_dash.left then
        return 'l..', x-STEP, y
    elseif tile == JELLY.markers.small_spawn.right or tile == JELLY.markers.small_dash.right then
        return 'r..', x+STEP, y

    elseif tile == JELLY.markers.big_spawn.down or tile == JELLY.markers.big_dash.down then
        y = y + 1
        while not JELLY._is_dash_mark(x, y) do
            y = y + 1
        end
        return 'D..', x, y
    elseif tile == JELLY.markers.big_spawn.up or tile == JELLY.markers.big_dash.up then
        y = y - 1
        while not JELLY._is_dash_mark(x, y) do
            y = y - 1
        end
        return 'U..', x, y
    elseif tile == JELLY.markers.big_spawn.left or tile == JELLY.markers.big_dash.left then
        x = x - 1
        while not JELLY._is_dash_mark(x, y) do
            x = x - 1
        end
        return 'L..', x, y
    elseif tile == JELLY.markers.big_spawn.right or tile == JELLY.markers.big_dash.right then
        x = x + 1
        while not JELLY._is_dash_mark(x, y) do
            x = x + 1
        end
        return 'R..', x, y
    end
end

function JELLY.build_program(x, y)
    local init_x = x
    local init_y = y
    local symbol
    symbol, x, y = JELLY._get_dash(x, y)
    program = {symbol}
    while x ~= init_x or y ~= init_y do
        symbol, x, y = JELLY._get_dash(x, y)
        table.insert(program, symbol)
    end
    return table.concat(program)
end

SHRIMP_COLORS = {
    COLOR.LIGHT_RED,
}


WORLD = {
    WIDTH = 999,
    HEIGHT = 999,

    WATER_MAX_HEIGHT = 800 + 17*8,

    -- Что, думаешь это просто случайные магические числа?
    --
    -- Как бы не так!
    --
    -- Все просто: 0.8 это соотношение сторон ширины губ Мона Лизы к длине её
    -- носа, а 0.006 это процент говорящих рыб среди всех океанских видов.
    -- Поскольку говорящие рыбы говорят только в присутсвии Мона Лизы, чтобы
    -- заставить рыбу говорить, нужно вынести её на сушу (в Лувр). Вот отсюда
    -- мы и рассчитаем трение, действующее на рыбу на земле!
    GROUND_FRICTION = math.pow(0.8, 1 / 0.006),
    WATER_FRICTION = math.pow(0.97, 1 / 0.006),

    TILE = {
        GLASS = {214, 215},
        SOLID = { 17, 18, 50,
            40, 41, 42, 43,
            56, 57, 58, 59,
            72, 73, 74, 75,
            88, 89, 90, 91,
            214, 215,

            16*16, 16*16 + 1, 16*16 + 2, 16*16 + 3,
            16*17, 16*17 + 1, 16*17 + 2, 16*17 + 3,
            16*18, 16*18 + 1, 16*18 + 2,
        },
        WATER = { 32, 33, 34, 49,
            24, 25, 26, 27,
            104, 105, 106, 107,
            39, 39+16, 39+16*2, 39+16*3
        },
        TOP_WATER = { 32 },
    },

    WATER_COLOR_TOP = COLOR.BLUE,
    WATER_COLOR_BOTTOM = COLOR.LIGHT_BLUE,
}

MICRO_FISH_SPAWN_TILE = 224


GRAVITY = 200


ASSETS = {}

function ASSETS:loadAll()
    self.music = love.audio.newSource('content/music.mp3', 'static')

    self.cut = love.graphics.newImage('content/cut.png')

    self.microFish = love.graphics.newImage('content/micro-fish.png')
    self.miniFish = love.graphics.newImage('content/mini-fish.png')
    self.mollusk = love.graphics.newImage('content/mollusk.png')
    self.bubble3x3 = love.graphics.newImage('content/bubble3x3.png')
    self.bubble4x4 = love.graphics.newImage('content/bubble4x4.png')
    self.bubble6x6 = love.graphics.newImage('content/bubble6x6.png')
    self.jellySpritesheet = love.graphics.newImage('content/jelly.png')
    self.fishSpritesheet = love.graphics.newImage('content/fish.png')
    self.checkpointSpritesheet = love.graphics.newImage('content/checkpoint.png')
    self.testTexture = love.graphics.newImage('content/testTexture.png')
    self.whiteSquare2x2 = love.graphics.newImage('content/whiteSquare2x2.png')
    self.tilesheet = love.graphics.newImage('content/tilemap/tilesheet.png')
    self.whitePixel = love.graphics.newImage('content/whitePixel.png')
    self.ripple = love.graphics.newImage('content/ripple.png')

    self.microFishGrid = anim8.newGrid(16, 16, self.microFish:getPixelWidth(), self.microFish:getPixelHeight())
    self.molluskGrid = anim8.newGrid(48, 16, self.mollusk:getPixelWidth(), self.mollusk:getPixelHeight())
    self.miniFishGrid = anim8.newGrid(5, 6, self.miniFish:getPixelWidth(), self.miniFish:getPixelHeight())
    self.cutGrid = anim8.newGrid(16, 16, self.cut:getPixelWidth(), self.cut:getPixelHeight())

    self.tilemap = love.filesystem.load('content/tilemap/map.lua')() -- <- Загружаем lua файл и тут же его исполняем. Наверное? Я не уверен зачем это

    self.jellyGrid = anim8.newGrid(16, 16, self.jellySpritesheet:getPixelWidth(), self.jellySpritesheet:getPixelHeight())
    -- self.jellyIdleAnimation = anim8.newAnimation(jellyGrid('1-2', 1), 0.5)
    -- self.jellyPrepareAnimation = anim8.newAnimation(jellyGrid(3, 1), 1)
    -- self.jellyDashAnimation = anim8.newAnimation(jellyGrid(4, 1), 1)

    -- self.jellyPinkIdleAnimation = anim8.newAnimation(jellyGrid('5-6', 1), 0.5)
    -- self.jellyPinkPrepareAnimation = anim8.newAnimation(jellyGrid(7, 1), 1)
    -- self.jellyPinkDashAnimation = anim8.newAnimation(jellyGrid(8, 1), 1)

    self.fishGrid = anim8.newGrid(16, 16, self.fishSpritesheet:getPixelWidth(), self.fishSpritesheet:getPixelHeight())
    -- self.fishIdleAnimation = anim8.newAnimation(fishGrid(1, 1), 1)
    -- self.fish_static_animations = {
    --     left = anim8.newAnimation(fishGrid(1, 1), 1),
    --     right = anim8.newAnimation(fishGrid(1, 2), 1),
    --     up = anim8.newAnimation(fishGrid(1, 3), 1),
    --     down = anim8.newAnimation(fishGrid(1, 4), 1),
    -- }

    local checkpointAnimation = anim8.newGrid(8, 8, self.checkpointSpritesheet:getPixelWidth(), self.checkpointSpritesheet:getPixelHeight())
    self.checkpointActiveAnimation = anim8.newAnimation(checkpointAnimation('1-4', 1), 0.5)
    self.checkpointDisabledAnimation = anim8.newAnimation(checkpointAnimation('5-8', 1), 0.5)

    self.rippleGrid = anim8.newGrid(16, 16, self.ripple:getPixelWidth(), self.ripple:getPixelHeight())

    local testGrid = anim8.newGrid(16, 16, self.testTexture:getPixelWidth(), self.testTexture:getPixelHeight())
    self.testAnimation = anim8.newAnimation(testGrid(1, 1), 0.5)

    self.waterShader = love.graphics.newShader(SHADERS_SOURCES.water)
    self.waterSurfaceShader = love.graphics.newShader(SHADERS_SOURCES.waterSurface)
end

SHADERS_SOURCES = {

waterSurface = [[
extern number y;
extern number height;
extern vec4 colorTop;
extern vec4 colorBottom;

extern number time;
extern number center;
extern number strength;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    number actualY = y + (texture_coords.y * height);
    number gradientT = (actualY - 64.0) / 320.0;

    vec4 gradientColor = vec4(mix(colorBottom.rgb, colorTop.rgb, gradientT), 1);

    number amplitude = 0.6;
    number waterCutoff = amplitude;
    number frequency = 10;
    number waveSpeed = 1;
    number waveFadeOut = 0.5;

    number centerLeft = center + time;
    number centerRight = center - time;
    number distFromCenter = min(abs(texture_coords.x - centerLeft), abs(texture_coords.x - centerRight));
    number fadeOut = mix(1, 0, time / 1.0);

    number wave = fadeOut * strength * max(0, waveFadeOut - distFromCenter) * amplitude * cos(frequency * (distFromCenter - waveSpeed * time));

    if (texture_coords.y > waterCutoff + wave) {
        return gradientColor;
    } else {
        return vec4(0);
    }
}
]],

water = [[
extern number y;
extern number height;
extern vec4 colorTop;
extern vec4 colorBottom;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    number actualY = y + (texture_coords.y * height);
    number gradientT = (actualY - 64.0) / 320.0;

    vec4 gradientColor = vec4(mix(colorBottom.rgb, colorTop.rgb, gradientT), 1);
    return gradientColor;//vec4(gradientT, gradientT, 0, 1);
}
]],

}
