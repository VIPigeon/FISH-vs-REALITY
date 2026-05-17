Input = {}

function Input.init()
    Input.actions = {}

    for name, action in pairs(KEYBINDS) do
        -- TODO: Зарефакторить эту гадость
        Input.actions[action.name] = {
            down = false,
            justPressed = false,
        }
        Input.actions[action.name].name = action.name
        Input.actions[action.name].keys = action.keys
    end
end


function Input.isDown(action)
    return Input.actions[action.name].down
end


function Input.isJustPressed(action)
    return Input.actions[action.name].justPressed
end


function Input.update()
    for _, action in pairs(Input.actions) do
        local action = Input.actions[action.name]

        local down = false
        for _, key in ipairs(action.keys) do
            if love.keyboard.isScancodeDown(key) then
                down = true
                break
            end
        end

        action.justPressed = false
        if down and not action.down then
            action.justPressed = true
        end
        action.down = down
    end
end
