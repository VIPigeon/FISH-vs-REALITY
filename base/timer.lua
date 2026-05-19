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


function Timer:restart()
    self.currentTime = self.duration
end
