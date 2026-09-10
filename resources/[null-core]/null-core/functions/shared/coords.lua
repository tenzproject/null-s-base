null.fct.GenerateRandomCoordAroundPoint = function(baseCoords, radius)
    local attempts = 0
    local maxAttempts = 1000
    local validCoord = nil
    local minimumRadius = 15.0
    
    while attempts < maxAttempts and validCoord == nil do
        local randomAngle = math.random() * 2 * math.pi
        local randomDistance = math.random() * radius + minimumRadius
        
        local newX = baseCoords.x + randomDistance * math.cos(randomAngle)
        local newY = baseCoords.y + randomDistance * math.sin(randomAngle)
        local _, groundZ = GetGroundZExcludingObjectsFor_3dCoord(newX, newY, baseCoords.z + 150.0, true)

        
        if _ and groundZ and Vdist(newX, newY, groundZ, baseCoords.x, baseCoords.y, baseCoords.z) <= radius and (groundZ - baseCoords.z) <= 4.0 and groundZ >= 0.0 then
            validCoord = vector3(newX, newY, groundZ)
        end
        
        attempts = attempts + 1
    end
    
    if validCoord == nil then
        validCoord = baseCoords
    end
    
    return validCoord
end

exports("GenerateRandomCoordAroundPoint", null.fct.GenerateRandomCoordAroundPoint)


null.fct.JsonCoordsToVect3 = function(pos)
    return vector3(pos.x, pos.y, pos.z)
end
