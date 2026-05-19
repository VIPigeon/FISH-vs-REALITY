Pool = {}
Pool.__index = Pool

function Pool:new()
    local object = {
        items = {},
        used = {},
        generation = {},
        freeList = {1},
    }

    setmetatable(object, self)
    return object
end


function Pool:put(item)
    local slot = table.remove(self.freeList)

    if slot > #self.items then
        table.insert(self.items, item)
        table.insert(self.generation, 1)
        table.insert(self.used, true)
        table.insert(self.freeList, 1 + #self.items)
    end

    self.used[slot] = true
    self.items[slot] = item

    return {index = slot, generation = self.generation[slot]}
end


function Pool:get(handle)
    local index = handle.index
    local generation = handle.generation
    if self.used[index] and self.generation[index] == generation then
        return self.items[index], true
    else
        return nil, false
    end
end


function Pool:delete(handle)
    local index = handle.index
    local generation = handle.generation

    if self.used[index] then
        if self.generation[index] == generation then
            self.used[index] = false
            self.generation[index] = 1 + self.generation[index]
            table.insert(self.freeList, index)
        else
            error('invalid handle')
        end
    else
        error('invalid handle')
    end
end


function Pool:foreach(func)
    for index, item in ipairs(self.items) do
        if self.used[index] then
            func(item, {index = index, generation = self.generation[index]})
        end
    end
end


function Pool:capacity()
    assert(#self.items == #self.used)
    return #self.items
end


function Pool:count()
    local count = 0
    self:foreach(function(_item)
        count = count + 1
    end)
    return count
end
