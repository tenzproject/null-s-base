local Zones = {}
null.fct.utils.CreateZoneFunction = LPH_NO_VIRTUALIZE(function(id, zonetype, coords, zoneFunction, time, radius)
    if Zones[id] ~= nil then return end
    if zonetype == "circle" then
        Zones[id] = CircleZone:Create(coords, radius, {
            name="circle_zones_"..id,
            --debugColor = {0, 200, 0, 100},
            --debugPoly = false,
            useZ = true,
            data = {
                id = id,
                time = time,
                func = zoneFunction,
            }
        })
    end
    Zones[id]:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            if zoneFunction and type(zoneFunction) == "function" then
                if time then
                    local can = ActionCooldown('canExecuteZoneFunction_'..id, time, false)
                    if can then
                        zoneFunction()
                    end
                else
                    zoneFunction()
                end
            end
        end
    end)
end)