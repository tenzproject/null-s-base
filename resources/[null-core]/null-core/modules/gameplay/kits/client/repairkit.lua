RegisterNetEvent('null:kit:mecano:repair')
AddEventHandler('null:kit:mecano:repair', function()
    local playerPed = PlayerPedId()
    local coords    = GetEntityCoords(playerPed)

    if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
        local vehicle = nil

        if IsPedInAnyVehicle(playerPed, false) then
            vehicle = GetVehiclePedIsIn(playerPed, false)
        else
            vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
        end

        if DoesEntityExist(vehicle) then
            null.fct.draw.AddTimerBar("Réparation de la Carrosserie :",{endTime=GetGameTimer()+60*1000*0.19})
            TriggerEvent('null:kit:mecano:canrepairanim')
            Citizen.CreateThread(function()
                GetVehicleEngineHealth(vehicle)
                local moteur = GetVehicleEngineHealth(vehicle)
                Citizen.Wait(10000)
                SetVehicleBodyHealth(vehicle, 1000.0)
                SetVehicleFixed(vehicle)
                SetVehicleDeformationFixed(vehicle)
                SetVehicleEngineHealth(vehicle, moteur)
                ClearPedTasksImmediately(playerPed)
                ESX.ShowNotification(('~g~Carrosserie \n~s~installé avec ~g~succès'))
                null.fct.draw.RemoveTimerBar()
            end)
        end
    end
end)


RegisterNetEvent('null:kit:mecano:canrepairanim')
AddEventHandler('null:kit:mecano:canrepairanim', function()
    TriggerEvent('null:kit:mecano:repairanim')
    Wait(3000)
    TriggerEvent('null:kit:mecano:repairanim')
    Wait(3000)
    TriggerEvent('null:kit:mecano:repairanim')
end)

RegisterNetEvent('null:kit:mecano:repairanim')
AddEventHandler('null:kit:mecano:repairanim', function()
    local dict, anim = 'amb@world_human_vehicle_mechanic@male@base', 'base'
    local playerPed = PlayerPedId()
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 5000, 0, 0.0, false, false, false)
end)
