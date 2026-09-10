function GetFuel(vehicle)
    return DecorGetFloat(vehicle, Config.Fuel.FuelDecor)
end

function SetFuel(vehicle, fuel)
    if type(fuel) == 'number' and fuel >= 0 and fuel <= 100 then
        SetVehicleFuelLevel(vehicle, fuel + 0.0)
        DecorSetFloat(vehicle, Config.Fuel.FuelDecor, GetVehicleFuelLevel(vehicle))
    end
end
exports('SetFuel', function(veh, fuel) SetFuel(veh, fuel) end)
exports('GetFuel', function(veh) return GetFuel(veh) end)

function FuelLoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Citizen.Wait(1) end
    end
end

function FuelRound(num, n)
    local mult = 10 ^ (n or 0)
    return math.floor(num * mult + 0.5) / mult
end

function FuelDrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

function FuelCreateBlip(coords)
    local blip = AddBlipForCoord(coords)
    SetBlipSprite(blip, 361)
    SetBlipScale(blip, 0.5)
    SetBlipColour(blip, 6)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Station-Service")
    EndTextCommandSetBlipName(blip)
    return blip
end

function FuelFindNearestPump()
    local coords = GetEntityCoords(PlayerPedId())
    local pumpObject, pumpDistance = 0, 1000.0
    local handle, object = FindFirstObject()
    local success
    repeat
        if Config.Fuel.PumpModels[GetEntityModel(object)] then
            local d = #(coords - GetEntityCoords(object))
            if d < pumpDistance then
                pumpDistance = d
                pumpObject = object
            end
        end
        success, object = FindNextObject(handle, object)
    until not success
    EndFindObject(handle)
    return pumpObject, pumpDistance
end
