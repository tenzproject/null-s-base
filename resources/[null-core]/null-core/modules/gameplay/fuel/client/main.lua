local isNearPump = false
local isFueling = false
local currentFuel = 0.0
local currentCost = 0.0
local currentCash = 0
local fuelSynced = false
local inBlacklisted = false

local function ManageFuelUsage(vehicle)
    if not DecorExistOn(vehicle, Config.Fuel.FuelDecor) then
        SetFuel(vehicle, math.random(200, 800) / 10)
    elseif not fuelSynced then
        SetFuel(vehicle, GetFuel(vehicle))
        fuelSynced = true
    end

    if IsVehicleEngineOn(vehicle) then
        local rpm = FuelRound(GetVehicleCurrentRpm(vehicle), 1)
        local usage = Config.Fuel.FuelUsage[rpm] or 0.0
        local classMult = Config.Fuel.Classes[GetVehicleClass(vehicle)] or 1.0
        SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - usage * classMult / 10)
    end
end

CreateThread(function()
    DecorRegister(Config.Fuel.FuelDecor, 1)

    for index = 1, #Config.Fuel.Blacklist do
        if type(Config.Fuel.Blacklist[index]) == 'string' then
            Config.Fuel.Blacklist[GetHashKey(Config.Fuel.Blacklist[index])] = true
        else
            Config.Fuel.Blacklist[Config.Fuel.Blacklist[index]] = true
        end
    end
    for index = #Config.Fuel.Blacklist, 1, -1 do
        table.remove(Config.Fuel.Blacklist, index)
    end

    while true do
        Wait(1000)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped) then
            local vehicle = GetVehiclePedIsIn(ped)
            inBlacklisted = Config.Fuel.Blacklist[GetEntityModel(vehicle)] == true
            if not inBlacklisted and GetPedInVehicleSeat(vehicle, -1) == ped then
                ManageFuelUsage(vehicle)
            end
        else
            if fuelSynced then fuelSynced = false end
            if inBlacklisted then inBlacklisted = false end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(250)
        local pumpObject, pumpDistance = FuelFindNearestPump()
        if pumpDistance < 2.5 then
            isNearPump = pumpObject
            local before = currentCash
            local source = "none"
            if ESX.getAccountMoney then
                currentCash = ESX.getAccountMoney('cash') or 0
                source = "ESX.getAccountMoney"
            elseif ESX.PlayerData and ESX.PlayerData.accounts then
                source = "ESX.PlayerData.accounts"
                for i = 1, #ESX.PlayerData.accounts do
                    if ESX.PlayerData.accounts[i].name == 'cash' then
                        currentCash = ESX.PlayerData.accounts[i].money
                        break
                    end
                end
            end
            if before ~= currentCash then
                print(("[FUEL DEBUG] near pump | source=%s | currentCash=%s"):format(source, tostring(currentCash)))
                if ESX.PlayerData and ESX.PlayerData.accounts then
                    for i = 1, #ESX.PlayerData.accounts do
                        local a = ESX.PlayerData.accounts[i]
                        print(("[FUEL DEBUG]   account[%d] name=%s money=%s"):format(i, tostring(a.name), tostring(a.money)))
                    end
                else
                    print("[FUEL DEBUG] ESX.PlayerData.accounts is nil")
                end
            end
        else
            isNearPump = false
            Wait(math.ceil(pumpDistance * 20))
        end
    end
end)

AddEventHandler('null:fuel:startTick', function(pumpObject, ped, vehicle)
    currentFuel = GetVehicleFuelLevel(vehicle)
    while isFueling do
        Wait(500)
        local oldFuel = DecorGetFloat(vehicle, Config.Fuel.FuelDecor)
        local fuelToAdd = math.random(10, 20) / 10.0
        local extraCost = fuelToAdd / 1.5 * Config.Fuel.CostMultiplier

        if not pumpObject then
            if GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100 >= 0 then
                currentFuel = oldFuel + fuelToAdd
                SetPedAmmo(ped, 883325847, math.floor(GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100))
            else
                isFueling = false
            end
        else
            currentFuel = oldFuel + fuelToAdd
        end

        if currentFuel > 100.0 then
            currentFuel = 100.0
            isFueling = false
        end

        currentCost = currentCost + extraCost

        if currentCash >= currentCost then
            SetFuel(vehicle, currentFuel)
            TriggerEvent('null:fuel:update3DStation', currentCost, currentFuel)
        else
            isFueling = false
        end
    end

    if pumpObject then
        TriggerServerEvent('null:fuel:pay', currentCost)
    end
    currentCost = 0.0
end)

AddEventHandler('null:fuel:refuelFromPump', function(pumpObject, ped, vehicle)
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Wait(1000)
    SetCurrentPedWeapon(ped, -1569615261, true)
    FuelLoadAnimDict("timetable@gardener@filling_can")
    TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)

    TriggerEvent('null:fuel:startTick', pumpObject, ped, vehicle)
    Wait(200)
    TriggerEvent('null:fuel:start3DStation', pumpObject, currentCost or 0, currentFuel or 0)

    CreateThread(function()
        while isFueling do
            TriggerEvent('null:fuel:update3DStation', currentCost or 0, currentFuel or 0, pumpObject)
            Wait(350)
        end
    end)

    while isFueling do
        for _, controlIndex in pairs(Config.Fuel.DisableKeys) do
            DisableControlAction(0, controlIndex)
        end
        if pumpObject then
            ESX.ShowHelpNotification(Config.Fuel.Strings.CancelFuelingPump)
        end
        if not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
            TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
        end
        if IsControlJustReleased(0, 38) or DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) or (isNearPump and GetEntityHealth(pumpObject) <= 0) then
            isFueling = false
            break
        end
        Wait(0)
    end

    ClearPedTasks(ped)
    RemoveAnimDict("timetable@gardener@filling_can")
    TriggerEvent('null:fuel:stop3DStation')
    isFueling = false
end)

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if not isFueling and ((isNearPump and GetEntityHealth(isNearPump) > 0) or (GetSelectedPedWeapon(ped) == 883325847 and not isNearPump)) then
            if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
                local pumpCoords = GetEntityCoords(isNearPump)
                FuelDrawText3D(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, Config.Fuel.Strings.ExitVehicle)
            else
                local vehicle = GetPlayersLastVehicle()
                local vehicleCoords = GetEntityCoords(vehicle)
                if DoesEntityExist(vehicle) and #(GetEntityCoords(ped) - vehicleCoords) < 2.5 then
                    if not DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) then
                        local stringCoords = GetEntityCoords(isNearPump)
                        local canFuel = true
                        if GetSelectedPedWeapon(ped) == 883325847 then
                            stringCoords = vehicleCoords
                            if GetAmmoInPedWeapon(ped, 883325847) < 100 then
                                canFuel = false
                            end
                        end
                        if GetVehicleFuelLevel(vehicle) < 95 and canFuel then
                            print(("[FUEL DEBUG] check buy | currentCash=%s | fuelLevel=%s"):format(tostring(currentCash), tostring(GetVehicleFuelLevel(vehicle))))
                            if currentCash > 0 then
                                ESX.ShowHelpNotification("Presse ~INPUT_PICKUP~ pour remplir le véhicule")
                                if IsControlJustReleased(0, 38) then
                                    print("[FUEL DEBUG] E pressed -> refuelFromPump")
                                    isFueling = true
                                    TriggerEvent('null:fuel:refuelFromPump', isNearPump, ped, vehicle)
                                    FuelLoadAnimDict("timetable@gardener@filling_can")
                                end
                            else
                                ESX.ShowNotification(Config.Fuel.Strings.NotEnoughCash)
                                Wait(2500)
                            end
                        elseif not canFuel then
                            FuelDrawText3D(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Fuel.Strings.JerryCanEmpty)
                        else
                            FuelDrawText3D(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Réservoir plein')
                        end
                    end
                end
            end
        else
            Wait(250)
        end
        Wait(0)
    end
end)

CreateThread(function()
    for _, coords in pairs(Config.Fuel.GasStations) do
        FuelCreateBlip(coords)
    end
end)

exports('getVehFuel', function(veh)
    return tostring(math.ceil(GetVehicleFuelLevel(veh)))
end)
