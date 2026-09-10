null.fct.math.RotationToDirection = function(rot)
	rot = rot or GetGameplayCamRot(2)
	local rotZ = rot.z  * ( 3.141593 / 180.0 )
	local rotX = rot.x  * ( 3.141593 / 180.0 )
	local c = math.cos(rotX)
	local multXY = math.abs(c)   
	local res = vector3((math.sin(rotZ) * -1) * multXY, math.cos(rotZ) * multXY, math.sin(rotX)) 
	return res 
end