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

    PURPLE = lume.color('#46425e'),
    BLUE = lume.color('#15788c'),
    LIGHT_BLUE = lume.color('#00b9be'),
    RED = lume.color('#ff6973'),
    LIGHT_RED = lume.color('#ffb0a3'),
    BRIGHTEST = lume.color('#ffeecc'),

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

ROTATE_RIGHT =      0.5 * math.pi
ROTATE_LEFT  = -1 * 0.5 * math.pi
ROTATE_180 =              math.pi


PLAYER = {
    WATER_ACCELERATION = 180,
    WATER_BOUNCE = 0.5,
    WALL_BOUNCE = 0.67, -- когда рыба на суше
    GROUND_ACCELERATION = 36,
    MAX_VELOCITY = 120,

    SPAWN_X = 40,
    SPAWN_Y = 80,

    MIN_V_FOR_BOUNCE = 39,
    JUMP = {
        -- MIN_T = 0.1,
        -- MAX_T = 1.1,
        -- MIN_FORCE = 800,
        -- MAX_FORCE = 5800,
        -- F — Force 😎
        short = {T=0, F=1500 * 1.8 * 0.016},
        middle = {T=0.2, F=2400 * 1.8 * 0.016},
        high = {T=0.2, F=4400 * 1.2 * 0.016},
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
            'short',
            'short',
            'short',
            'short',
            'middle',
            'middle',
            'middle',
            'middle',
            'middle',
            'middle',
            'middle',
            'high',
        },
    },
    OXYGEN = 15, -- время жизни без воды (секунды)
    OXYGEN_INCOME = 10, -- скорость восстановления кислорода в воде (в секунду)
}

JELLY = {
    DASH_STRENGTH = 60,
    BIG_DASH_STRENGTH = 120,
    TICK_FREQUENCY = 0.5, -- Раз в 0.5 секунд переходим на следующую команду в программе
    DASH_COOLDOWN = 3,
}

WORLD = {
    WIDTH = 999,
    HEIGHT = 999,

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
        SOLID = { 17, 18, 50 },
        WATER = { 32, 33, 34, 49 },
    }
}


GRAVITY = 200


ASSETS = {}

function ASSETS:loadAll()
    self.jellySpritesheet = love.graphics.newImage('content/jelly.png')
    self.checkpointSpritesheet = love.graphics.newImage('content/checkpoint.png')
    self.testTexture = love.graphics.newImage('content/testTexture.png')
    self.whiteSquare2x2 = love.graphics.newImage('content/whiteSquare2x2.png')
    self.tilesheet = love.graphics.newImage('content/tilemap/tilesheet.png')

    self.tilemap = love.filesystem.load('content/tilemap/map.lua')() -- <- Загружаем lua файл и тут же его исполняем. Наверное? Я не уверен зачем это

    local jellyGrid = anim8.newGrid(8, 16, self.jellySpritesheet:getPixelWidth(), self.jellySpritesheet:getPixelHeight())
    self.jellyIdleAnimation = anim8.newAnimation(jellyGrid('1-2', 1), 0.5)
    self.jellyPrepareAnimation = anim8.newAnimation(jellyGrid(3, 1), 1)
    self.jellyDashAnimation = anim8.newAnimation(jellyGrid(4, 1), 1)

    self.jellyPinkIdleAnimation = anim8.newAnimation(jellyGrid('5-6', 1), 0.5)
    self.jellyPinkPrepareAnimation = anim8.newAnimation(jellyGrid(7, 1), 1)
    self.jellyPinkDashAnimation = anim8.newAnimation(jellyGrid(8, 1), 1)

    local checkpointAnimation = anim8.newGrid(8, 8, self.checkpointSpritesheet:getPixelWidth(), self.checkpointSpritesheet:getPixelHeight())
    self.checkpointActiveAnimation = anim8.newAnimation(checkpointAnimation('1-4', 1), 0.5)
    self.checkpointDisabledAnimation = anim8.newAnimation(checkpointAnimation('5-8', 1), 0.5)

    local testGrid = anim8.newGrid(16, 16, self.testTexture:getPixelWidth(), self.testTexture:getPixelHeight())
    self.testAnimation = anim8.newAnimation(testGrid(1, 1), 0.5)
end
