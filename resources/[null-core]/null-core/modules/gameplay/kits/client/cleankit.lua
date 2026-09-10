RegisterNetEvent('null:kit:mecano:clean')
AddEventHandler('null:kit:mecano:clean', function()
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
            TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_MAID_CLEAN', 0, true)
            Citizen.CreateThread(function()
                Citizen.Wait(10000)

                SetVehicleDirtLevel(vehicle, 0)
                ClearPedTasksImmediately(playerPed)

                ESX.ShowNotification('~g~Carrosserie \n~s~néttoyé avec ~g~succès')
            end)
        else
            ESX.ShowNotification('Aucun véhicule')
        end
    end
end)