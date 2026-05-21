Timer = {}
Timer.__index = Timer

function Timer:new(duration)
    local object = {
        duration = duration,
        currentTime = duration,
    }

    setmetatable(object, self)
    return object
end


function Timer:tick()
    self.currentTime = Time.tick(self.currentTime)
end


function Timer:elapsed()
    return self.currentTime == 0.0
end


function Timer:timeElapsed()
    return self.duration - self.currentTime
end


function Timer:restart()
    self.currentTime = self.duration
end


function Timer:stop()
    self.currentTime = 0
end


CountingTimer = {}
CountingTimer.__index = CountingTimer

function CountingTimer:new()
    local object = {
        duration = 0.0,
    }

    setmetatable(object, self)
    return object
end


function CountingTimer:tick(deltaTime)
    self.duration = self.duration + deltaTime
end


function CountingTimer:reset()
    self.duration = 0
end
