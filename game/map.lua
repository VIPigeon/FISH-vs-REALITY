Map = {}

function Map.init(tilemap)
    Map.tilemap = tilemap
    Map.terrain = tilemap.layers[1]
    Map.spawn = tilemap.layers[2]
    Map.decorations = tilemap.layers[3]
    Map.water = tilemap.layers[4]
end

function Map.get(tileX, tileY, layer)
    layer = layer or 'terrain'
    
    if 0 <= tileX and tileX < Map[layer].width and 0 <= tileY and tileY < Map[layer].height then
        local tileId = Map[layer].data[1 + tileY * Map[layer].width + tileX]
        if tileId ~= 0 then
            tileId = tileId - 1
        end
        return tileId
    else
        return 0
    end
end


function Map.isWater(tileX, tileY, y)
    assert(y ~= nil)
    local tileId = Map.get(tileX, tileY, 'water')
    if table.contains(WORLD.TILE.TOP_WATER, tileId) then
        local floor = math.floor(y / 8)
        return y > 1 + 8*floor
    end
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
