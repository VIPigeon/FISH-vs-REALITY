Map = {}

function Map.init(tilemap)
    Map.tilemap = tilemap
    Map.terrain = tilemap.layers[1]
    Map.spawn = tilemap.layers[2]
end

function Map.get(tileX, tileY)
    if 0 <= tileX and tileX < Map.terrain.width and 0 <= tileY and tileY < Map.terrain.height then
        local tileId = Map.terrain.data[1 + tileY * Map.terrain.width + tileX]
        if tileId ~= 0 then
            tileId = tileId - 1
        end
        return tileId
    else
        return 0
    end
end


function Map.isWater(tileId)
    return table.contains(WORLD.TILE.WATER, tileId)
end


function Map.isSolid(tileX, tileY)
    local tileId = Map.get(tileX, tileY)
    return table.contains(WORLD.TILE.SOLID, tileId)
end


function Map.worldToTile(x, y)
    local tileX = math.floor(x / 8)
    local tileY = math.floor(y / 8)
    return tileX, tileY
end

function Map.worldToTileX(x)
    local tileX = math.floor(x / 8)
    return tileX
end

function Map.getTileTextureRegion(tileId)
    local row = math.floor(tileId / 16)
    local col = tileId - 16 * row
    return 8*col, 8*row, 8, 8
end
