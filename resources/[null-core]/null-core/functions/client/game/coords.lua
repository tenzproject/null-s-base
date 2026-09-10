local sin = math.sin
local cos = math.cos
local torad = math.pi / 180

local waterMaterials  = {
    [-1775485061] = true,
    [1635937914] = true,
    [-1136057692] = true
}

null.fct.game.GetCoordsInFrontOfCam = LPH_NO_VIRTUALIZE(function(...)   
	local unpack = table.unpack   
	local coords,direction = GetGameplayCamCoord(), null.fct.math.RotationToDirection()   
	local inTable  = {...}   
	local retTable = {}    
	if (#inTable == 0) or (inTable[1] < 0.000001) then
		inTable[1] = 0.000001
	end    
	for k,distance in pairs(inTable) do     
		if (type(distance) == "number") then       
			if (distance == 0) then         
				retTable[k] = coords       
			else         
				retTable[k] = vector3(coords.x + (distance * direction.x), coords.y + (distance * direction.y), coords.z + (distance * direction.z))  
			end     
		end   
	end   
	return unpack(retTable)
end)

null.fct.game.GetCoordsFromGamePlayCameraPointAtSynced = LPH_NO_VIRTUALIZE(function(ingoredEntity)
    local action = 0
    local distance = 1000
    local coordsVector =  GetFinalRenderedCamCoord() ;
    local rotationVectorUnrad = GetFinalRenderedCamRot(2);
    local rotationVector = rotationVectorUnrad * torad
    local directionVector =  vector3(-sin(rotationVector.z) * cos(rotationVector.x), (cos(rotationVector.z) * cos(rotationVector.x)), sin(rotationVector.x));
    local destination =  coordsVector + directionVector * distance ;
    local destination_temp = coordsVector + directionVector * 1 ;
    local getentitytype = function(entity)
       local type = GetEntityType(entity)
       local result = "solid"
       if type == 0 then 
          result = "solid"
       elseif type == 1 then 
          result = "ped"
       elseif type == 2 then 
          result = "vehicle"
       elseif type == 3 then 
          result = "object"
       end 
       return result
    end

    if StartExpensiveSynchronousShapeTestLosProbe then 
        local shapeTestId = StartExpensiveSynchronousShapeTestLosProbe(destination_temp, destination, 511, ingoredEntity or PlayerState.ped, 4)
        local shapeTestResult , hit , endCoords , surfaceNormal , entityHit = GetShapeTestResult(shapeTestId)
        ground, newZ = GetGroundZFor_3dCoord(endCoords.x, endCoords.y, endCoords.z + 0.5)

        return hit and vector3(endCoords.x, endCoords.y, newZ or endCoords.z)
    end
end)