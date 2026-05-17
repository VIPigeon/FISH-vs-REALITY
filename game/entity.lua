Entity = {}

function Entity:new()
    local object = {}
    return object
end


function Entity.addComponent(entity, component)
    entity[component.name] = table.deepcopy(component)
    return entity[component.name]
end
